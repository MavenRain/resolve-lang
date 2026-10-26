#!/bin/sh
# The resolution chain gate (S7 s3c, PLAN 4.7). Deploy examples/resolvekit.lang,
# check the size limits (the runtime at most 24576 bytes, EIP-170; the initcode
# at most 49152 bytes, EIP-3860), then run the calls of PLAN section 7 on the
# chain: the four-call casts of poll 0 (the DAO poll) and its opening, the stake
# of member a1 in market 0, the proposal and the challenge of market 0, the
# casts of poll 1 (the dispute of market 0) and its opening (a tie), then
# finalize and claim. A step at BLOCK 0 is `evm run` from the caller (the voter
# address, or a1 for take and claim); a step at BLOCK > 0 is a t8n step from
# the key address (numbered=1, O36). The words are the output of
# `build/ballottool contract`: the ballots of voters 0, 1, 2 in poll 0 and of
# voters 0, 2 in poll 1 (the stake of a1 puts nums 1 in slot 1 of the ring of
# poll 1), and the T1 openings. The line `resolvekit gas rows` gives the
# execution gas of deploy and of each entry; the gate does not check it. It
# needs evm (go-ethereum), bc, od, build/slottool and build/ballottool. Run it
# from the kit root.
set -u
fail=0
steps=0
tmp=${TMPDIR:-/tmp}/langc-resolvekit.$$
mkdir -p "$tmp"
. test/evmchain.sh

prog=examples/resolvekit.lang
voter=0x00000000000000000000000000000000000000aa
member1=0x00000000000000000000000000000000000000a1
caller=$voter
numbered=1
token=00000000000000000000000000000000000000ee
build/ballottool contract >"$tmp/words" || { echo "FAIL resolvekit: ballottool"; exit 1; }
build/asmtool mock >"$tmp/mock" || { echo "FAIL resolvekit: asmtool mock"; exit 1; }

# acct ADDR: the storage rows `SLOT VALUE` of the account ADDR in tmp/dump
# (test/diff.sh).
acct() {
  awk -F'"' -v a="0x$1" 'NF == 3 && length($2) == 42 { p = (tolower($2) == a); next }
    p && NF >= 5 && length($2) == 66 && substr($2, 1, 2) == "0x" { print substr($2, 3), $4 }' "$tmp/dump"
}

# mock: the next steps have the `asmtool mock` runtime at the token address in
# mode 0 (it returns true) with no balances (test/diff.sh). nomock: no code at
# the token address.
mock() { alloc=",\"0x$token\":{\"balance\":\"0x0\",\"code\":\"0x$(cat "$tmp/mock")\",\"storage\":{}}"; }
nomock() { alloc=; }
nomock

# paid ADDR WANT: after a step with the mock, the mock balance of ADDR (slot
# ADDR, from 0) must equal WANT (hexnorm).
paid() {
  _got=$(awk -v a="$(pad "${1#0x}")" '$1 == a { v = tolower($2); sub(/^0x/, "", v); sub(/^0+/, "", v); print (v == "" ? "0" : v) }' "$tmp/mockrows")
  [ "$_got" = "$2" ] || { echo "FAIL resolvekit mock balance of $1: want $2, got ${_got:-none}"; fail=$((fail + 1)); }
}

# ws PREFIX NAMES...: the words PREFIX.NAME of tmp/words as `langc run`
# tokens, in the order of NAMES (the first row of each name).
ws() {
  _p=$1
  shift
  printf '%s\n' "$@" | awk -v p="$_p" 'NR == FNR { if (!($1 in v)) v[$1] = $2; next } { print v[p $1] "u" }' "$tmp/words" -
}

# hw NAME: the word NAME of tmp/words as hexnorm (a view result).
hw() { hexnorm "$(ws "" "$1" | cut -c3- | tr -d u)"; }

# sig Q V, slot Q V J, seal Q V: the arguments of the castSig, castSlot J and
# castSeal calls of voter V in poll Q.
sig() {
  echo "$1u"
  ws "q$1b$2" ix iy j0c1x j0c1y j0c2x j0c2y j1c1x j1c1y j1c2x j1c2y c1 s1 s2 s3
}
slot() {
  echo "$1u"
  ws "q$1b$2" ix iy
  echo "$3u"
  ws "q$1b$2j$3" a0x a0y b0x b0y a1x a1y b1x b1y e0 e1 z0 z1
}
seal() {
  echo "$1u"
  ws "q$1b$2" ix iy sumax sumay sumbx sumby sumz
}

# opening Q NAME: the arguments of openTally, the T1 opening NAME of poll Q.
opening() {
  echo "$1u"
  ws "q$1$2" d1x d1y a1x a1y b1x b1y z1 d2x d2y a2x a2y b2x b2y z2 n
}

# call WANT NAME BLOCK ARGS...: one step of the entry or view NAME with ARGS at
# NOW = BLOCK. At BLOCK 0 the step is `evm run` from the caller, at BLOCK > 0 a
# t8n step from the key address. The result must equal WANT: `out HEX` (HEX as
# hexnorm), ok or revert. An entry changes the storage of the next step.
call() {
  _want=$1 _name=$2 _block=$3
  shift 3
  steps=$((steps + 1))
  _from=$caller
  [ "$_block" = 0 ] || _from=0x$key
  _input=$(input "$prog" "$_name" "$@")
  if ! step "$_block" "${_block}u" "$_from" "$_input"; then
    echo "FAIL resolvekit $_name (step $steps): evm: $(head -n 1 "$tmp/dump")"
    fail=$((fail + 1))
    return
  fi
  # With the mock, tmp/raw holds the storage of all accounts: keep the
  # receiver rows only, and the mock rows in tmp/mockrows.
  if [ -n "$alloc" ]; then
    acct "$token" >"$tmp/mockrows"
    acct "$receiver" >"$tmp/own"
    mv "$tmp/own" "$tmp/raw"
  fi
  case $result in
    "out "*) _hex=${result#out }
      [ ${#_hex} -eq 64 ] && result="out $(hexnorm "$_hex")" ;;
  esac
  if [ "$result" != "$_want" ]; then
    echo "FAIL resolvekit $_name (step $steps): want $_want, got $result"
    fail=$((fail + 1))
  fi
}

# gasrow NAME: add the execution gas of the last call to the gas line as NAME:
# the trace summary gasUsed (gas) after a t8n step, else `evm run --statdump`
# of the same call on the same prestate (tmp/pre.json).
gasrows=
gasrow() {
  [ "$stepped" = t8n ] || gas=$(evm run --prestate "$tmp/pre.json" --receiver "0x$receiver" --sender "$_from" \
    --input "$_input" --statdump 2>&1 >/dev/null | awk '$1 == "EVM" { print $4 }')
  gasrows="$gasrows, $1 $gas"
}

# cast Q V BLOCK: the 4 calls of voter V in poll Q at BLOCK.
cast() {
  call ok castSig "$3" $(sig "$1" "$2")
  call ok castSlot "$3" $(slot "$1" "$2" 0)
  call ok castSlot "$3" $(slot "$1" "$2" 1)
  call ok castSeal "$3" $(seal "$1" "$2")
}

# tally Q NAME: the T1 words of poll Q (pollWord Q 4 .. 7) must equal the
# words c1x c1y c2x c2y of the opening NAME (the host sum).
tally() {
  call "out $(hw "q$1$2c1x")" pollWord 0 "$1u" 4u
  call "out $(hw "q$1$2c1y")" pollWord 0 "$1u" 5u
  call "out $(hw "q$1$2c2x")" pollWord 0 "$1u" 6u
  call "out $(hw "q$1$2c2y")" pollWord 0 "$1u" 7u
}

if ! deploy "$prog"; then
  echo "FAIL resolvekit deploy: $(head -n 1 "$tmp/dump")"
  rm -rf "$tmp"
  echo "resolvekit chain: 0 steps, 1 failures"
  exit 1
fi
init=$(build/langc --kit build "$prog")
# `evm run --create --statdump` prints the gas left (go-ethereum 1.14.12), not
# the gas used: the deploy gas is the genesis gas limit (0x1c9c380) minus it.
dgas=$((30000000 - $(evm run --prestate "$tmp/pre.json" --create --code "$init" --statdump 2>&1 >/dev/null |
  awk '$1 == "EVM" { print $4 }')))
ibytes=$((${#init} / 2))
rbytes=$(awk '{ print length($0) / 2; exit }' "$tmp/code")
echo "resolvekit size rows: runtime $rbytes bytes (limit 24576), initcode $ibytes bytes (limit 49152)"
[ "$rbytes" -le 24576 ] || { echo "FAIL resolvekit size: runtime $rbytes > 24576 (EIP-170)"; fail=$((fail + 1)); }
[ "$ibytes" -le 49152 ] || { echo "FAIL resolvekit size: initcode $ibytes > 49152 (EIP-3860)"; fail=$((fail + 1)); }

# Poll 0, voter 0: a seal with no slot 1 proof reverts, a second castSig after
# the seal reverts (N used).
call ok castSig 0 $(sig 0 0)
gasrow castSig
call ok castSlot 0 $(slot 0 0 0)
gasrow castSlot
call revert castSeal 0 $(seal 0 0)
call ok castSlot 0 $(slot 0 0 1)
call ok castSeal 0 $(seal 0 0)
gasrow "castSeal first"
call revert castSig 0 $(sig 0 0)
cast 0 1 0
gasrow "castSeal later"
cast 0 2 0
call "out 3" pollWord 0 0u 8u
tally 0 t1

# The opening of poll 0: at daoEnd (BLOCK 10) it reverts, after it (BLOCK 11)
# n 2 of 3 casts is a pass and sets the windows 5, 5 -> 8, 6 (windows = 256
# disputeWindow + voteWindow). A second opening reverts.
call revert openTally 10 $(opening 0 t1)
call "out 505" windows 0
call ok openTally 11 $(opening 0 t1)
gasrow openTally
call "out 806" windows 0
call "out 2" pollWord 0 0u 9u
call revert openTally 11 $(opening 0 t1)

# Market 0: a1 stakes 7 on outcome 0 before the deadline 10 (thus slot 1 of
# the ring of poll 1 is nums 1). A proposal before the deadline reverts; the
# proposal at BLOCK 12 (r 50: outcome 0) keeps the last challenge block 12 + 8
# = 20 in field 2 (the window after the pass of poll 0).
caller=$member1
mock
call ok take 0 0u 0u 7u
gasrow take
paid "$receiver" 7
nomock
caller=$voter
call "out 7" stakeOf 0 0u "$member1"
call revert propose 9 0u 50u
call ok propose 12 0u 50u
gasrow propose
call "out 14" fieldOf 0 0u 2u
call revert propose 12 0u 50u

# The challenge: rule 0 t = rule 0 r reverts (L5), a challenge after field 2
# (BLOCK 21) reverts. The challenge at BLOCK 13 (t 0: outcome 1) keeps the last
# voting block 13 + 6 = 19 in field 6.
call revert challenge 13 0u 50u
call revert challenge 21 0u 0u
call ok challenge 13 0u 0u
gasrow challenge
call "out 13" fieldOf 0 0u 6u
call revert challenge 13 0u 0u

# Poll 1: a cast after field 6 (BLOCK 20) reverts; voters 0 and 2 cast at
# BLOCK 15.
call revert castSig 20 $(sig 1 0)
cast 1 0 15
cast 1 2 15
call "out 2" pollWord 0 1u 8u
tally 1 t1

# The opening of poll 1: before field 6 + 1 it reverts, a finalize before the
# opening reverts, the T1 of voter 0 only (w1) reverts (not the tally). n 1 of
# 2 casts is a tie: the proposal stays (field 8 = 0).
call revert openTally 19 $(opening 1 t1)
call revert finalize 20 0u
call revert openTally 20 $(opening 1 w1)
call ok openTally 20 $(opening 1 t1)
call "out 1" pollWord 0 1u 9u
call "out 806" windows 0
call ok finalize 20 0u
gasrow finalize
call "out 1" fieldOf 0 0u 7u
call "out 0" fieldOf 0 0u 8u
call revert finalize 20 0u

# claim: a1 gets 7 * 7 / 7 (its stake is the pool of outcome 0); a second claim
# reverts (no stake).
caller=$member1
mock
call ok claim 0 0u
gasrow claim
paid "$member1" 7
call revert claim 0 0u
nomock
caller=$voter

rm -rf "$tmp"
echo "resolvekit gas rows: deploy $dgas$gasrows"
echo "resolvekit chain: $steps steps, $fail failures"
[ "$fail" -eq 0 ]
