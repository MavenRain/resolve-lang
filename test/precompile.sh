#!/bin/sh
# The precompile gate (slice S2, kickoff 1.5). Deploy examples/precompile.lang,
# then do one `evm run --prestate` step for each view and compare the result
# word with a constant. Each constant was confirmed at build (2026-10-15, evm
# 1.14.12) with a direct `evm run --input HEX --receiver 0x..0N` to the
# precompile address N (1 ecrecover, 6 ecAdd, 7 ecMul, 8 ecPairing) before it
# entered this file. The evaluator computes a closed ecAdd or ecMul (S8 B1):
# examples/bn254.lang gives k G in the host for each k of the mulX and mulY rows,
# with the same words. A closed ecrecover computes (S7 b4, test/secptool.c); ecPairing
# stays stuck (R17). This gate
# compares the chain result only. It needs evm (go-ethereum), bc, od and
# build/slottool. Run it from the kit root.
set -u
fail=0
steps=0
tmp=${TMPDIR:-/tmp}/langc-precompile.$$
mkdir -p "$tmp"
. test/evmchain.sh

prog=examples/precompile.lang
caller=0x00000000000000000000000000000000000000aa

# call WANT NAME ARGS...: one step of the view or entry NAME with ARGS at
# TIMESTAMP 1. The result must equal WANT: `out HEX` (HEX as hexnorm), `ok` or
# `revert`. An entry changes the storage of the next step.
call() {
  _want=$1 _name=$2
  shift 2
  steps=$((steps + 1))
  _input=$(input "$prog" "$_name" "$@")
  if ! step 1 1u "$caller" "$_input"; then
    echo "FAIL precompile $_name: evm: $(head -n 1 "$tmp/dump")"
    fail=$((fail + 1))
    return
  fi
  case $result in
    "out "*) _hex=${result#out }
      [ ${#_hex} -eq 64 ] && result="out $(hexnorm "$_hex")" ;;
  esac
  if [ "$result" != "$_want" ]; then
    echo "FAIL precompile $_name: want $_want, got $result"
    fail=$((fail + 1))
  fi
}

if ! deploy "$prog"; then
  echo "FAIL precompile deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  # 2G on BN254 (EIP-196): ecAdd (1,2) (1,2) and ecMul (1,2) 2.
  twoGx=30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3
  twoGy=15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4
  call "out $twoGx" addX 1u 2u 1u 2u
  call "out $twoGy" addY 1u 2u 1u 2u
  call "out $twoGx" mulX 1u 2u 2u
  call "out $twoGy" mulY 1u 2u 2u
  # ecMul (1,2) 0 is the point at infinity, (0, 0).
  call "out 0" mulX 1u 2u 0u
  call "out 0" mulY 1u 2u 0u
  # 3G, (r minus 1) G = (1, p minus 2) and r G = (0, 0), r the order of G1 (S8 B1;
  # confirmed 2026-10-18 with a direct `evm run` to 0x..07, evm 1.14.12).
  threeGx=769bf9ac56bea3ff40232bcb1b6bd159315d84715b8e679f2d355961915abf0
  threeGy=2ab799bee0489429554fdb7c8d086475319e63b40b9c5b57cdf1ff3dd9fe2261
  pMinusTwo=30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd45
  rMinusOne=0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000u
  rOrder=0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001u
  call "out $threeGx" mulX 1u 2u 3u
  call "out $threeGy" mulY 1u 2u 3u
  call "out 1" mulX 1u 2u "$rMinusOne"
  call "out $pMinusTwo" mulY 1u 2u "$rMinusOne"
  call "out 0" mulX 1u 2u "$rOrder"
  call "out 0" mulY 1u 2u "$rOrder"
  # (1, 1) is not on the curve: the precompile fails and the call reverts (R18).
  call revert addBad 2u
  # e(G1, G2) e(-G1, G2) = 1 (EIP-197), and the empty product is 1.
  call "out 1" pairOk
  call "out 1" pairNil
  # The go-ethereum ecrecover vector (core/vm/testdata/precompiles/ecRecover.json, CallEcrecover0).
  h=0x38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873eu
  sgood=0x789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02u
  addr=ceaccac640adf55b2028469bd36ba501f28b699d
  call "out $addr" recover "$h" 27 "$h" "$sgood"
  # s = 0 gives an empty output: the address is 0 (R18).
  call "out 0" recover "$h" 27 "$h" 0u
  # The same ecrecover statement twice (a fold over the pushed words, the end of
  # the list first): the valid s, then s = 0. The sum is the one address (M8).
  call ok sign "$sgood"
  call ok sign 0u
  call "out $addr" recoverSum
  # signedBy (S7 b4): the good signature against its signer; s = 0 (the address
  # 0, confirmed with a direct `evm run` to 0x..01) against the signer 0 fails.
  call "out 1" signedBy "$h" 27 "$h" "$sgood" "0x$addr"
  call "out 0" signedBy "$h" 27 "$h" 0u 0x0000000000000000000000000000000000000000
  # keccak256 of 64 zero bytes; `langc eval examples/precompile.lang hashZero` gives the same word.
  call "out ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5" hashv 0u 0u
  # leafStep i = natDiv i 2 + natMod i 2 (the parent index plus the side bit).
  call "out 4" leafStep 7
  call "out 3" leafStep 6
  call "out aa" addrWord 0x00000000000000000000000000000000000000aa
fi

# The threshold opening of examples/threshold.lang (S6, Q-S6-6): the words of
# `build/thresholdtool words` (n 3, t 2, m 1234, quorum {1, 2}; l2 = r - 1).
# Each ecMul and ecAdd word was confirmed at build (2026-10-23, evm 1.14.12)
# with a direct `evm run` to 0x..06 or 0x..07. z1 + 1 fails dleqOk, m 1235
# fails openOk.
prog=examples/threshold.lang
pk1x=0x1f8998908f24942c91e985c7d47ef1a72c4b50225e2eab95d035b5f35d266fb6u
pk1y=0x08e06bf52945ba6717f9228de2d3dba0ca205f0725120f2da2b61c3eaab51797u
c1x=0x06107e6b6511db3eb78edf5b81e309c1ce2d43ffc1f99878add70ec94232f5bdu
c1y=0x0c417387621eb1e2f78895cafc1ba63b3141ad838c1718913898a716e2513dccu
d1x=0x25c1f7b394999d8fb70dff84f4bcc6315445533a3ddc6cd2075111363b987422u
d1y=0x10bfba20e712970a914f6792b77ce1bd500fc1ec966107759a7c4870dbfbfff8u
a1x=0x1caead4e0da42c1d4db0d09ce41d43f5538a8087c752bcc266b550ba530d593cu
a1y=0x2cfbc233ebdfb0af1d6404d3081c9a7fea2878dcc855030affac01152287c93au
b1x=0x0248fe02c6a21f55aff1f6667808aa65978ad670f286d99420a02db797db175eu
b1y=0x0c78621e9e0babfefd760556856aed8940676de5f747157cdfd050e24d54c343u
z1=0x08fad840104489f5dc19df835b78abe11a9eb08068adb6954a52ed9dddafd5a3u
z1bad=0x08fad840104489f5dc19df835b78abe11a9eb08068adb6954a52ed9dddafd5a4u
d2x=0x3029e90d9f4a5c80381a88ec072552599f260a245b78110965e3ce4770cb80fcu
d2y=0x1962d546253839f2e4952e4b2ec720846ba74a00520fb5957bb54a602f58d86au
l1=2u
l2=0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000u
kx=0x24347111ca7ece60147a3c9f770e870aae28c84db57202855318ed8ce2808016u
ky=0x230ffa7d4bbc30d27d9eeba70a08008b72b6334751005274ac8aeb5c8fe4d19du
c2x=0x1bfeca9f35b9d24a06420451a37fff41a575a6e5ecf0d4a054d0120d08627aeeu
c2y=0x1d482f62e329fc2ee7c5579e6296989e50fc6b3f68ba6db6b4e20b4914552627u
if ! deploy "$prog"; then
  echo "FAIL threshold deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  call "out 1" dleqOk "$pk1x" "$pk1y" "$c1x" "$c1y" "$d1x" "$d1y" "$a1x" "$a1y" "$b1x" "$b1y" "$z1"
  call "out 0" dleqOk "$pk1x" "$pk1y" "$c1x" "$c1y" "$d1x" "$d1y" "$a1x" "$a1y" "$b1x" "$b1y" "$z1bad"
  call "out 24347111ca7ece60147a3c9f770e870aae28c84db57202855318ed8ce2808016" combineX "$d1x" "$d1y" "$l1" "$d2x" "$d2y" "$l2"
  call "out 230ffa7d4bbc30d27d9eeba70a08008b72b6334751005274ac8aeb5c8fe4d19d" combineY "$d1x" "$d1y" "$l1" "$d2x" "$d2y" "$l2"
  call "out 1" openOk "$c2x" "$c2y" "$kx" "$ky" 1234u
  call "out 0" openOk "$c2x" "$c2y" "$kx" "$ky" 1235u
fi

# The one-hot ballot proofs of examples/onehot.lang (S7, Q-S7-8): the words of
# `build/sigmatool words` (pk from blsag_key(5), ctx blsag_key(23), k 2,
# choice 1). Each ecMul, ecAdd and hash chain was confirmed at build
# (2026-10-23, evm 1.14.12) with a direct `evm run` to 0x..06, 0x..07 or a
# keccak code (intent-lang-work/S7-ec-confirm.sh). z + 1 fails randOk, the
# forged split of slot 0 (an encryption of 2) fails slotOk, and the split
# maxWord + 2 = 1 (modulo 2^256) passes without the trap of u256Add.
prog=examples/onehot.lang
wctx=0x165d47d57adae4a13e25107baeb75afb447248ec79152ef9fad26eac97ba177eu
wpkx=0x0968d432a7834f16726268caca7e1a398153743ee91bff7afa02f0ca6fdd1cefu
wpky=0x1b03a01c8bb70557c6ae6cc0e854ca3f1ff99bf86a8c867437e1d654b8238854u
s0c1x=0x0b32ee9502fbea21ed59bf4e9198cef815d87a58c9f30e87c950dc5faa0f5df8u
s0c1y=0x1eab782fcf92ebbc712c3d3a89fcbb8859038df33c8c792ce2c240c9a14364edu
s0c2x=0x1dc1189d0143f3bbf1196014d6ccb0d04189c26a0241d6338266428060556131u
s0c2y=0x171be7a10d9c991e95d1a22d9d1d0917a9ff0590a872d7614179eb22bf20817fu
s0a0x=0x25135c67b0307427422c6fe242eeeed17eb7945f8412c9277282da0125cdfeecu
s0a0y=0x07b5b92c527d5fd666715fb20a6da4e625e4f150ab71549cec8146e291f0149au
s0b0x=0x0606985761b99eaf9f2e80d64a21dcf2d89c1310e411395cdaf535e9d095eda3u
s0b0y=0x035e3eacb3f7097011e82df135aff72cb88fdbc173ceadd77c897332419a27e9u
s0a1x=0x1e88846757fb3f8b971ccab757f29a23f861358fc7425f889230ea4755764cb8u
s0a1y=0x2f20e36c608268bfec51d1814b66c82acbd45c268e755a1f91472cbc1e65ccb9u
s0b1x=0x2e8bda41bd08f2562e22cd58a9b90732a542662f331269ba72addfd02f983ee5u
s0b1y=0x0d49abdac41195fb6b248647c9ad9010d9c25e1ea9146fdbdcb5b7f378cbb148u
s0e0=0x6faeac6b62fe2c187afe5c4bb48022021fe4108eaa20c48090fdfebe2c7edf78u
s0e1=0x0ef7d8fc7ba5b5aada617108f8009a0d400d74938749e744a5e44e08bee0c1f1u
s0z0=0x134b833a9077298f8b4c871292751dbb6b6b5eb263ac0ca0bddad910930600adu
s0z1=0x0964a8f24a8737cca4409c4ff3ad3307e27101709b88508d59061c42c22c50d7u
s1c1x=0x1872c00f9a13d4ef35dedbbae4050f22038c055feaa32963d2923976b5d55e69u
s1c1y=0x1db9f31831e6861aad480f5c7ebf778deda29d7bba582730418ee98499867e0fu
sumc1x=0x2f87c2138b9a349174c49a78c8bf1b12ab7b639b953135c0063e1d3db5ed4294u
sumc1y=0x12bb1fff7bfbf6d742d74adb8e0f9b9ca9e86c1cb64551cb59bd21303ef262f1u
sumc2x=0x1f64eaba25542c7dee1b41bbe25b36b20713de4cdbaf1817883c7da1ba7290b5u
sumc2y=0x2a88156a2bd65b8241108574ad3335797ffd995d8201836741ab5d53c593d25cu
sumax=0x1357fdbc12f002c9350a6850f66d0f53a50eb71a0352ce19ce594259b19c32e5u
sumay=0x0d9e5cad710ea83bd84be8c626488de680ed285cba48866813a8d3ee1fc4cbbdu
sumbx=0x2c4716f2bfcfca295be12849d64d8d442780f1d27e452459825b85de8da52f28u
sumby=0x1bee6e8a256611724dc7e3966b75945b4722c180e0de3d738d0d37ae803cf3ddu
sumz=0x2943f4819ae982763e3016a5d6f4a54ba7ec3ed2939186bf6f51baa02ac06d30u
sumzbad=0x2943f4819ae982763e3016a5d6f4a54ba7ec3ed2939186bf6f51baa02ac06d31u
fc1x=0x13595f66a0a2e2d61015668c55f8bcd0288e619830ca19aa601f4f024821c75bu
fc1y=0x2be3b092f87a4bb4f2d8a5246c14541f1ad0d730bf1591cf158b5772a13b4eb9u
fc2x=0x02c60b6cb0a59f5546a6371be9833002bd69c38253e67ea53e294686e07bb00eu
fc2y=0x052185f10c8b7838fdb0abf4279629523ece4f08bfd236765ef369beeb5f459cu
fa0x=0x092033173cacce9202703314152285ae3a6d3c10c49438a7a2af8a8fd072f95eu
fa0y=0x0b52cbce26803a3889d1c18d83c88d57c26d70b45d81abf3970b305b782d0946u
fb0x=0x253c919fd3bb2ba6d2d2724f53ca60e350b4ae9d51639d825e25b34609c39649u
fb0y=0x295f9276881af8976fb39112281cee6ce1a54f74989034850cdfc9ea375459c0u
fa1x=0x136c7c5f4608b42851699653b678a174294b83051c934f5e47ccc177f769832eu
fa1y=0x16cee4a2fc0b36f54460f7da5f06b6a96ff1762f2fe7d0f629f394551977891fu
fb1x=0x221a789806ab05b0de16b97cb797dc21f13811a8bb43ff88fda988faa06730deu
fb1y=0x129e7d4979010c9897e787f976e5a9633949b2816ec1ba2030cb7eba31612a7eu
fe0=0x1f9db1de5bdcdf7689acd41f1944259d1709531bd6c420081a60b695e9a87738u
fe1=0x0ecd2e5cb928db41d562959a119b5e280aae61e7b3e45ed566a6579bf4aed0d0u
fz0=0x1155cee05885e4b13c009fc8a8a0493b2823c1febfc3daf50b33e1e0a6eb4841u
fz1=0x20f0a7e0737ce8053f5d12c4b64a2251b04b38e2aad9cb1cc8f2f286d7904d06u
if ! deploy "$prog"; then
  echo "FAIL onehot deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  call "out 1" randOk "$wctx" "$wpkx" "$wpky" "$sumc1x" "$sumc1y" "$sumc2x" "$sumc2y" 1u "$sumax" "$sumay" "$sumbx" "$sumby" "$sumz"
  call "out 0" randOk "$wctx" "$wpkx" "$wpky" "$sumc1x" "$sumc1y" "$sumc2x" "$sumc2y" 1u "$sumax" "$sumay" "$sumbx" "$sumby" "$sumzbad"
  call "out 1" slotOk "$wctx" 0u "$wpkx" "$wpky" "$s0c1x" "$s0c1y" "$s0c2x" "$s0c2y" "$s0a0x" "$s0a0y" "$s0b0x" "$s0b0y" "$s0a1x" "$s0a1y" "$s0b1x" "$s0b1y" "$s0e0" "$s0e1" "$s0z0" "$s0z1"
  call "out 0" slotOk "$wctx" 0u "$wpkx" "$wpky" "$fc1x" "$fc1y" "$fc2x" "$fc2y" "$fa0x" "$fa0y" "$fb0x" "$fb0y" "$fa1x" "$fa1y" "$fb1x" "$fb1y" "$fe0" "$fe1" "$fz0" "$fz1"
  call "out 1" splitView 1u 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffu 2u
  call "out 2f87c2138b9a349174c49a78c8bf1b12ab7b639b953135c0063e1d3db5ed4294" sumX "$s0c1x" "$s0c1y" "$s1c1x" "$s1c1y"
  call "out 12bb1fff7bfbf6d742d74adb8e0f9b9ca9e86c1cb64551cb59bd21303ef262f1" sumY "$s0c1x" "$s0c1y" "$s1c1x" "$s1c1y"
fi

# The dispute ballots of examples/ballot.lang (resolve-lang S6 s2, a port of
# intent-lang 3df9d96, Q-S6-2 (a)): the words of `build/ballottool words` (the
# election key of thresholdtool, n 3, t 2; the tweaked ring of the charter keys
# blsag_key(0 .. 2) in the dispute of market 0; voters 0, 1 and 2 vote right,
# right and left). Each WANT is the host result of test/ballottool.c (`ballot
# regressions`). Voter 0's slot proof under voter 1's key image fails
# slotBound (the ctx binds I), voter 1's slot 0 C1 in voter 0's digest fails
# ballotSig, the host 3-ballot sums open to left 1 and right 2, and verdict
# keeps left on a tie (Q-S6-3 (a)).
# Counts are canonical scalars: zero opens, and r and r + 1 are refused.
prog=examples/ballot.lang
b0ix=0x0e50a85d002876d229a89eabdaa865f0cf1b2a28a406a3f656db9460f766f709u
b0iy=0x0631739add132c194ae61fe0e931af39224f576e51467bd83930f8527e3a84c9u
b0c1=0xe20e448bce65cf03aa3f5719228a0faf868629d98876b3d5fade3c053ac70506u
b0s1=0x0af7f618a8f7513a5c17d41004fb57186d448974e5001f0ad7282f07dc9e0a98u
b0s2=0x03545c771eb67286e01faec322464d255c43484737dbb942c16aeea1103628d0u
b0s3=0x28abd4901fb2e7b22dd8dc74ece10b051a8ae13019252542294edc2bf42852abu
b0j0c1x=0x19d99b0aa847886456ab1542e0892af1cbbdbb0bcf2481d01e2b064296c94303u
b0j0c1y=0x2fd4eb33f20c6f14a41809b930381868c0f6e935c2a01c90cc60f8cb7c8505e4u
b0j0c2x=0x159fd2c2d51efc351a18419cf235f538f7bd39bc2733eb57e11aaa9401de089au
b0j0c2y=0x22237d10e62a38c0ca0f98649a891029031ec6980ce695d0c9c77f4cc9df10b6u
b0j0a0x=0x1a8b1d491694753ec12930a8077eeac83fe51474fe7f062f91d28f9c5f45faaeu
b0j0a0y=0x09cc92fe40c589ae56c6017ee1732a87f5194b1930daf657b65536e8d3e1b3dau
b0j0b0x=0x0accfb668ac332e095dc95199c22ddd105635a468435d150fa33c3357c8de49cu
b0j0b0y=0x2c44df2f68070165692df7b826cd868c88b0e169679c6f3794e677a625c1ddd2u
b0j0a1x=0x0392ce880893d9e887f13e8edcdc72ed0abf8d464e6aa56ae84a8e07d3a28095u
b0j0a1y=0x2552f05f98d3ace16a70085d59ede3bf0d261d04bfd703e9526ddb7c2e6ba750u
b0j0b1x=0x1981b445327da47b57fabfa53234bbc437d6e0d8d38adfc3b067068579ed1bf1u
b0j0b1y=0x0db20076bc7df7f1e9500aede4ec34a50ed762447dcc2b6af34ab46ae92d3e73u
b0j0e0=0xbe41782850ca94cb952a4fda072e83eee5434ab898abd344e1a7f58c752c3870u
b0j0e1=0x7434ecdb2938abf106302e42124863487cb21b1fd88257c557514a9994b27f32u
b0j0z0=0x1b6a63a8e46adc13ad6321a5aeb4ab259b9b51fe49a99c772657a79f38bb4aaau
b0j0z1=0x1c7fe1600f630339a1e67a44ea52e1efadc7649ae90d88ae5a246f920e0ecea6u
b0j1c1x=0x17632c471eb5baf6f57784c2ab78176caf1845f618f996648f228442cd2a598eu
b0j1c1y=0x166d6aa743f0e68fa2fdda9a6b3fd6b1e36714bc1ca3d38ae02aefde1c22cccau
b0j1c2x=0x19aad7250ae98ca793974faf3e6942fe1845edeea01f381813ae6763edbe5e2eu
b0j1c2y=0x0cfe8d6685599dd25cbfd02e2648a473f660d9ef8769a1f51d95927d0028d506u
b0j1a0x=0x1db345e3b821a2419db431c6b7c8e5561d6020bb78eb1ce7659b4b3b43321335u
b0j1a0y=0x0653e826ad9fc7f8dc198557cef369908a69ec117228e2b1f9820e9aad0512d7u
b0j1b0x=0x0bb74ffc865da19daeb1a73b0c63af3baac80f48b4bbeeae359bc8d22827748au
b0j1b0y=0x127ebb0d1b800ac0df09af50dc0ce29cecab8e8e73dec8806ca52db66533e042u
b0j1a1x=0x1e615960b84503a7ed4976673ef83712c22d0e0c99ca92df045dcd6d039a62b6u
b0j1a1y=0x1228db65e3c0644ed9815a73022cdae1f167b37170087dfbdfc8547ba256de35u
b0j1b1x=0x2b1819d9a563ef2efa34ac6a368a9f800409b5ec411a4055baa83636676155eeu
b0j1b1y=0x263213f9fbf11e918ec6b20cb0f15338cdcac5cbf84152f32e95dad02d71a17cu
b0j1e0=0xb82f9f61927f9a599e5a1f3b8b86949021e5de001f2ceec426a11e0332c3ab56u
b0j1e1=0x79a386639807d0e3fb814c8d2b2bd35817bbe13b6527181b172ffacee2517557u
b0j1z0=0x1848643d884995881fe9143581bca3f22796a0b77e6d2e1c72eaee72b56a14b6u
b0j1z1=0x2936cb03e4129e8dfea521300ab2f22697d49de40f46b7761a30948994662f32u
b0sumax=0x0f40da95b3af6210be6b86338261e239f5f835379958762919c5a30a1d38eb79u
b0sumay=0x11bf9418d6715e52d2dd65c9c7a15802a19962eb24f6a01b7304959c31010586u
b0sumbx=0x304f707e55994cc0ba19687a6bc2faa9c6bbc4cf3fdab1092a9ee930d9956f39u
b0sumby=0x0f4e35dad76340fd7b4eab125b6bacdac8fee5a57afd50cc16d2b955e9764729u
b0sumz=0x008fd914cdd73ba9cffb284820f15932c0ea18b20947184e7972ee6d55166378u
b1ix=0x0e1dcaf2266b3cceac64f0041047ea70b8b68ad2b735baebadddff048def4bc7u
b1iy=0x0bc5825d77097f8901106851f78f80a12b4c6f1aff25f78a539e524ac964719fu
b1j0c1x=0x25653dc2daab15a45605fa7fa43271b90e6717990540e3e1fa5700f2ac083622u
b1j0c1y=0x10331a6c868f1cb03177c7ff1fee004d02595534d91f3599cde5311793089196u
tlc2x=0x2b2d08481576d5b68b648410c291a2f8bc896ca8cfacc48e7aa2b48af35ce2fbu
tlc2y=0x101b5b2c665a85c2e206ab6d9993b5aaca51b0bd958626d9b974cb24705ef4a1u
tlkx=0x2c76a87f791e1f4d8bdcb7bb5ae116eb42729c1021112415de4395528e448197u
tlky=0x0319dae7d43061ee60d42d9fbc77b0767e96d69a077631141d36360c63e80d87u
trc2x=0x229fb27d30b30c900795978feb795536f8e7dbed2912390d25f891791b67bf8eu
trc2y=0x0f6da5f1430b36c72cb18ec74c49f0b265c9e12898976128338f03704a1c80fbu
trkx=0x0bf5c60c2216b5b8388dd7ce3a1a456bdf5df8310a9cfbe50be33de63b99ae65u
trky=0x038cfbb48d31c51151d46dbcc0b44e11300221d291e3bb80712a9d9bd075e884u
if ! deploy "$prog"; then
  echo "FAIL ballot deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  call "out b3b52a1ea6c078d39ccc8e706097e86410f81a8e05a7de9579f8b4b3c4d04a65" ballotCtx "$b0ix" "$b0iy"
  call "out 1" slotBound "$b0ix" "$b0iy" 0u "$b0j0c1x" "$b0j0c1y" "$b0j0c2x" "$b0j0c2y" "$b0j0a0x" "$b0j0a0y" "$b0j0b0x" "$b0j0b0y" "$b0j0a1x" "$b0j0a1y" "$b0j0b1x" "$b0j0b1y" "$b0j0e0" "$b0j0e1" "$b0j0z0" "$b0j0z1"
  call "out 1" slotBound "$b0ix" "$b0iy" 1u "$b0j1c1x" "$b0j1c1y" "$b0j1c2x" "$b0j1c2y" "$b0j1a0x" "$b0j1a0y" "$b0j1b0x" "$b0j1b0y" "$b0j1a1x" "$b0j1a1y" "$b0j1b1x" "$b0j1b1y" "$b0j1e0" "$b0j1e1" "$b0j1z0" "$b0j1z1"
  call "out 0" slotBound "$b1ix" "$b1iy" 0u "$b0j0c1x" "$b0j0c1y" "$b0j0c2x" "$b0j0c2y" "$b0j0a0x" "$b0j0a0y" "$b0j0b0x" "$b0j0b0y" "$b0j0a1x" "$b0j0a1y" "$b0j0b1x" "$b0j0b1y" "$b0j0e0" "$b0j0e1" "$b0j0z0" "$b0j0z1"
  call "out 1" sumBound "$b0ix" "$b0iy" "$b0j0c1x" "$b0j0c1y" "$b0j0c2x" "$b0j0c2y" "$b0j1c1x" "$b0j1c1y" "$b0j1c2x" "$b0j1c2y" "$b0sumax" "$b0sumay" "$b0sumbx" "$b0sumby" "$b0sumz"
  call "out 1" ballotSig "$b0j0c1x" "$b0j0c1y" "$b0j0c2x" "$b0j0c2y" "$b0j1c1x" "$b0j1c1y" "$b0j1c2x" "$b0j1c2y" "$b0c1" "$b0s1" "$b0s2" "$b0s3" "$b0ix" "$b0iy"
  call "out 0" ballotSig "$b1j0c1x" "$b1j0c1y" "$b0j0c2x" "$b0j0c2y" "$b0j1c1x" "$b0j1c1y" "$b0j1c2x" "$b0j1c2y" "$b0c1" "$b0s1" "$b0s2" "$b0s3" "$b0ix" "$b0iy"
  call "out 1" openOk "$tlc2x" "$tlc2y" "$tlkx" "$tlky" 1u
  call "out 1" openOk "$trc2x" "$trc2y" "$trkx" "$trky" 2u
  call "out 1" openOk 0u 0u 0u 0u 0u
  call "out 0" openOk 0u 0u 0u 0u 21888242871839275222246405745257275088548364400416034343698204186575808495617u
  call "out 0" openOk "$tlc2x" "$tlc2y" "$tlkx" "$tlky" 21888242871839275222246405745257275088548364400416034343698204186575808495618u
  call "out 1" verdict 1u 2u
  call "out 0" verdict 1u 1u
fi

# The private cast of examples/zkcast.lang (S8 B3a): the ring (p0, p1) at poll 0.
# The six words are the `dao b0` row of test/prove/expect.txt (choice, c_1, s_1,
# s_2, I.x, I.y): six refusals revert (S8 B3b), the valid cast enters, count 1
# reads 1, the same key image reverts.
prog=examples/zkcast.lang
c1=39381386088514315497347125331661662002366806678711758872472619958305300356361u
s1=10556691046619535408078082753355190806958972782948105030448836431921968396625u
s2=5075046572376896310100317466143363171635445558286582457308097647558945948934u
ix=10761449505403964036076757638925780734653286855769319211451479689235022075489u
iy=7813043007448227325775284969956458831967279497483528366357925175793623591926u
# The refusal words: bad1 to bad5 = c_1, s_1, s_2, I.x, I.y of a signature by
# zkKey 2 over the ring (p0, p2) at poll 0 (the host refuses it on the cast
# ring); p71 to p75 = the b0 member signed at poll 7u; s1r = s_1 + r.
bad1=114233635948204567937611136005807964635379552110520686947477480399687734882175u
bad2=4606903119986625213584159387736508097390161799663041052171944740195199651320u
bad3=19405452480297225842144819244991036144939704859909575586366782468791467929709u
bad4=12143800741274053729678695342025405071161578280145823471976847353119162962133u
bad5=5478805016161928785310155891281398518466491099139863695584469452713860577342u
p71=115326832689243201939208783265390243471483834046477764896127408546428269123821u
p72=6848704374829197146497408100537308754776627187049601801861139456475064325019u
p73=5324371756747053231067432293918824366492735010707968715625973090356803969703u
p74=10761449505403964036076757638925780734653286855769319211451479689235022075489u
p75=7813043007448227325775284969956458831967279497483528366357925175793623591926u
s1r=32444933918458810630324488498612465895507337183364139374147040618497776892242u
if ! deploy "$prog"; then
  echo "FAIL zkcast deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  # Six refusals before the valid cast: the entry checks the used key first, so
  # a vector with the b0 key image placed after the cast would revert for the key.
  # A signer outside the ring (p0, p1): the hash chain does not close.
  call revert cast 1u "$bad1" "$bad2" "$bad3" "$bad4" "$bad5"
  # The b0 words with the choice flipped to 0: the choice is in the hash.
  call revert cast 0u "$c1" "$s1" "$s2" "$ix" "$iy"
  # The b0 member signed at poll 7u: the poll id is in the hash.
  call revert cast 1u "$p71" "$p72" "$p73" "$p74" "$p75"
  # I = (1, 1) is not on bn254: the ecMul precompile returns 0, the code reverts.
  call revert cast 1u "$c1" "$s1" "$s2" 1u 1u
  # I = (0, 0): the precompile takes infinity, the chain fails, the last flag refuses.
  call revert cast 1u "$c1" "$s1" "$s2" 0u 0u
  # s_1 + r: the precompile reduces mod r and the chain closes; u256Le s_1 rmax refuses.
  call revert cast 1u "$c1" "$s1r" "$s2" "$ix" "$iy"
  call ok cast 1u "$c1" "$s1" "$s2" "$ix" "$iy"
  call "out 1" count 1u
  call revert cast 1u "$c1" "$s1" "$s2" "$ix" "$iy"
fi

# The private cast of examples/zksel.lang (S7 s2 b2): the first argument sel
# selects ring element 0, thus the ring is (p0, p1) at sel 0u and (p2, p1) at
# sel 1u, at poll 0. The words A are the zkcast words above (`zksel sigA` of
# test/eval/expect.txt, member 0 over (p0, p1)). The words B are `zksel sigB`
# (member 2 over (p2, p1)). Both are for choice 1. Each signature enters only at
# the sel of its ring, and a used key image reverts.
prog=examples/zksel.lang
b1=18378777097721804545827648190024473973245883280630685881464974683515137495981u
b2=10311407951551484410553055345951414254060350714906874258009752520648351507903u
b3=9660660946426415475252185306110190857957752498164818308000009179865869923920u
b4=12143800741274053729678695342025405071161578280145823471976847353119162962133u
b5=5478805016161928785310155891281398518466491099139863695584469452713860577342u
if ! deploy "$prog"; then
  echo "FAIL zksel deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  # The words A at sel 1u: the ring (p2, p1) does not hold member 0.
  call revert cast 1u 1u "$c1" "$s1" "$s2" "$ix" "$iy"
  # The words B at sel 0u: the ring (p0, p1) does not hold member 2.
  call revert cast 0u 1u "$b1" "$b2" "$b3" "$b4" "$b5"
  call ok cast 0u 1u "$c1" "$s1" "$s2" "$ix" "$iy"
  call ok cast 1u 1u "$b1" "$b2" "$b3" "$b4" "$b5"
  call "out 2" count 1u
  # The key image of A is used.
  call revert cast 0u 1u "$c1" "$s1" "$s2" "$ix" "$iy"
fi

# The written DAO contract (S9 B1): the text of `langc contract examples/dao.lang`.
# The cast words come from `langc prove test/contract/ballots.lang NAME POLL`
# (choice, c_1, s_1, s_2, I.x, I.y): the prove ring depends only on the Member
# cardinality, 2 as in examples/dao.lang. Before 2 casts the outcome is 2 (no
# outcome). m0 votes 0 and m1 votes 1, so agree0 gives outcome 1; enact adopts
# constitution 1 and opens poll 1, where the poll 0 words of m0 revert.
build/langc contract examples/dao.lang >"$tmp/dao.lang"
prog="$tmp/dao.lang"
ballot() {
  build/langc prove test/contract/ballots.lang "$1" "$2" | tr '\n' ' '
}
if ! deploy "$prog"; then
  echo "FAIL contract deploy: $(head -n 1 "$tmp/dump")"
  fail=$((fail + 1))
else
  m0p0=$(ballot m0c0 0u)
  m0p1=$(ballot m0c0 1u)
  m1p0=$(ballot m1c1 0u)
  m1c2=$(ballot m1c2 0u)
  call "out 2" outcome
  call revert enact
  call "out 0" selfConstituting
  call ok cast $m0p0
  call revert cast $m0p0
  # A valid signature over choice 2: the contract has 2 choices.
  call revert cast $m1c2
  call ok cast $m1p0
  call "out 1" count 0u
  call "out 1" count 1u
  call "out 1" outcome
  call ok enact
  call "out 1" poll
  call "out 1" constitution
  call "out 0" selfConstituting
  call revert cast $m0p0
  call ok cast $m0p1
  call "out 1" count 0u
fi

# The differential (S9 B2) on the EVM: for each row of test/contract/diff.txt,
# the calls of test/run.sh on a new deploy of the written contract `langc
# contract examples/PROG.lang --start START`. The SELF word is 1 for flagYes and
# 0 for flagNo. The rows are read on fd 3, so evm and langc cannot read them.
diffs=0
while read -r line <&3; do
  case $line in --*|'') continue ;; esac
  set -- ${line%% => *}
  want=${line#* => }
  diffs=$((diffs + 1))
  if ! build/langc contract "examples/$1.lang" --start "$2" >"$prog" || ! deploy "$prog"; then
    echo "FAIL differential deploy $line: $(head -n 1 "$tmp/dump")"
    fail=$((fail + 1))
    continue
  fi
  ballots=$5
  before=$fail
  shift 5
  for name in "$@"; do
    call ok cast $(build/langc prove "test/contract/$ballots.lang" "$name" 0u | tr '\n' ' ')
  done
  call "out ${want%% *}" outcome
  call ok enact
  call "out ${want#* }" selfConstituting
  [ "$fail" -eq "$before" ] || echo "FAIL differential row: $line"
done 3<test/contract/diff.txt
echo "differential: $diffs EVM rows checked"

rm -rf "$tmp"
echo "precompile: $steps steps checked"
echo "precompile gate: $fail failures"
[ "$fail" -eq 0 ]
