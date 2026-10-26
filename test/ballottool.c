/* Host ballot regressions (resolve-lang S6 s2, a port of intent-lang 3df9d96
   test/ballottool.c, Q-S6-2 (a)): the encrypted dispute ballots of PLAN 4.4.
   Voters 0, 1 and 2 of the charter keys blsag_key(0 .. 2) cast one-hot
   ballots over Verdict (k 2: left is slot 0, right is slot 1) under the
   election key of thresholdtool (n 3, t 2). The dispute id d of market 0 in
   the deployment of examples/ring.lang, d = hash(hash(1, 0xc1), 0), replaces
   the poll. The ring is the tweaked ring K_i + t G, and the signing key is
   k_i + t mod r, with t = hash(1, d) mod r. Each proof carries ctx =
   hash(hash(hash(ballotTag, I.x), I.y), d) for the key image I of the voter,
   and the ring signs the digest of the slot ciphertexts. With the argument
   `words` it prints the chain constants of examples/ballot.lang, one
   `name 0x<word>` per line (p0 .. p2 are the keys before the tweak). With
   the argument `contract` it prints the cast and opening words of the two
   polls of examples/resolvekit.lang in the same form (see `contract`). */
#include <stdio.h>
#include <string.h>

#include "front/blsag.h"
#include "front/elgamal.h"
#include "front/sigma.h"
#include "front/threshold.h"

#define N 3u
#define T 2u
#define K 2u
#define BITS 16u
/* "ballot" and "digest" as big endian words. */
#define BALLOT_TAG 0x62616c6c6f74ull
#define DIGEST_TAG 0x646967657374ull
/* The scalar order r of BN254 G1, in decimal. */
#define FR_DEC "21888242871839275222246405745257275088548364400416034343698204186575808495617"
/* The known answer of ballotCtx for voter 0: a recomputation would follow a
   change of the tag, this word does not. */
#define CTX0 "0xb3b52a1ea6c078d39ccc8e706097e86410f81a8e05a7de9579f8b4b3c4d04a65"
/* The receiver address of examples/resolvekit.lang, "receiver" as a word. */
#define RECEIVER 0x7265636569766572ull

/* One cast: the bLSAG words c_1, s_1 .. s_3, I.x, I.y over the digest, the
   ctx of I, the slots and the sum proof. */
typedef struct {
  U256 sig[N + 3u];
  U256 ctx;
  U256 digest;
  ElgCipher cts[K];
  SigOr slots[K];
  SigDleq sum;
} Ballot;

static void hex(char *out, size_t size, const U256 *w) {
  snprintf(out, size, "0x%016llx%016llx%016llx%016llx", (unsigned long long)w->limb[3], (unsigned long long)w->limb[2],
           (unsigned long long)w->limb[1], (unsigned long long)w->limb[0]);
}

static void word(const char *prefix, const char *name, const U256 *w) {
  char text[67];
  hex(text, sizeof text, w);
  printf("%s%s %s\n", prefix, name, text);
}

static void point(const char *prefix, const char *x, const char *y, const G1 *p) {
  U256 a;
  U256 b;
  g1_to_words(&a, &b, p);
  word(prefix, x, &a);
  word(prefix, y, &b);
}

/* ballotCtx: the hash chain from ballotTag over I.x, I.y and the poll. */
static void ballot_ctx(U256 *out, const U256 *ix, const U256 *iy, const U256 *poll) {
  u256_from_u64(out, BALLOT_TAG);
  thr_hash(out, out, ix);
  thr_hash(out, out, iy);
  thr_hash(out, out, poll);
}

/* ballotDigest: the hash chain from digestTag over C1.x, C1.y, C2.x, C2.y of
   slot 0, then of slot 1. */
static void ballot_digest(U256 *out, const ElgCipher *cts) {
  U256 w[4];
  uint32_t j;
  uint32_t i;
  u256_from_u64(out, DIGEST_TAG);
  for (j = 0; j < K; j++) {
    g1_to_words(&w[0], &w[1], &cts[j].c1);
    g1_to_words(&w[2], &w[3], &cts[j].c2);
    for (i = 0; i < 4u; i++)
      thr_hash(out, out, &w[i]);
  }
}

/* reduceOnce and modR of examples/ring.lang: x - r when r <= x, and five
   steps take a word below r. */
static void reduce_once(U256 *x) {
  U256 r;
  const char *c;
  u256_from_u64(&r, 0u);
  for (c = FR_DEC; *c; c++)
    u256_scale_add(&r, 10u, (uint32_t)(*c - '0'));
  if (u256_cmp(&r, x) <= 0)
    u256_sub(x, x, &r);
}

static void mod_r(U256 *x) {
  uint32_t i;
  for (i = 0; i < 5u; i++)
    reduce_once(x);
}

/* The dispute id d of market 0 and its tweak t (examples/ring.lang):
   deployment = hash(chainId 1, 0xc1), d = hash(deployment, 0) and
   t = hash(tweakTag 1, d) mod r. */
static void dispute_of(U256 *d, U256 *t) {
  U256 w;
  U256 a;
  u256_from_u64(&w, 1u);
  u256_from_u64(&a, 0xc1u);
  thr_hash(d, &w, &a);
  u256_from_u64(&a, 0u);
  thr_hash(d, d, &a);
  thr_hash(t, &w, d);
  mod_r(t);
}

/* The ballot of VOTER for CHOICE. The key image does not depend on the
   message, so a first signature gives I, and so ctx, before the slots
   exist. Fixed entropy for reproducible vectors only, never a live ballot.
   1, or 0 when a step refuses. */
static int cast(Ballot *b, const G1 *ring, const G1 *pk, const U256 *poll, const U256 *tweak, uint32_t voter, uint32_t choice) {
  U256 x;
  U256 seed;
  blsag_key(&x, voter);
  /* The signing key in the dispute: shift k t of examples/ring.lang. */
  u256_add(&x, &x, tweak);
  reduce_once(&x);
  blsag_key(&seed, 40u + voter);
  if (!blsag_sign(b->sig, ring, N, &x, poll, poll))
    return 0;
  ballot_ctx(&b->ctx, &b->sig[N + 1u], &b->sig[N + 2u], poll);
  if (sig_onehot_prove(b->cts, b->slots, &b->sum, pk, K, choice, &seed, &b->ctx) != SIG_OK)
    return 0;
  ballot_digest(&b->digest, b->cts);
  return blsag_sign(b->sig, ring, N, &x, poll, &b->digest);
}

/* The sum of slot J over the three ballots. */
static void slot_sum(ElgCipher *out, const Ballot *b, uint32_t j) {
  elg_add(out, &b[0].cts[j], &b[1].cts[j]);
  elg_add(out, out, &b[2].cts[j]);
}

/* The parts of the quorum {1, 2} for CT. */
static void quorum(ThrPart *parts, const ThrShare *shares, const ElgCipher *ct) {
  thr_partial(&parts[0], &shares[0], ct);
  thr_partial(&parts[1], &shares[1], ct);
}

static int fail(const char *name) {
  fprintf(stderr, "FAIL ballot %s\n", name);
  return 0;
}

static void slot_words(const char *prefix, const ElgCipher *ct, const SigOr *s) {
  point(prefix, "c1x", "c1y", &ct->c1);
  point(prefix, "c2x", "c2y", &ct->c2);
  point(prefix, "a0x", "a0y", &s->a0);
  point(prefix, "b0x", "b0y", &s->b0);
  point(prefix, "a1x", "a1y", &s->a1);
  point(prefix, "b1x", "b1y", &s->b1);
  word(prefix, "e0", &s->e0);
  word(prefix, "e1", &s->e1);
  word(prefix, "z0", &s->z0);
  word(prefix, "z1", &s->z1);
}

static void cipher_words(const char *prefix, const ElgCipher *ct) {
  point(prefix, "c1x", "c1y", &ct->c1);
  point(prefix, "c2x", "c2y", &ct->c2);
}

static void part_words(const char *prefix, const char *d, const char *a, const char *b, const char *z, const ThrPart *p) {
  char x[8];
  char y[8];
  snprintf(x, sizeof x, "%sx", d);
  snprintf(y, sizeof y, "%sy", d);
  point(prefix, x, y, &p->d);
  snprintf(x, sizeof x, "%sx", a);
  snprintf(y, sizeof y, "%sy", a);
  point(prefix, x, y, &p->a);
  snprintf(x, sizeof x, "%sx", b);
  snprintf(y, sizeof y, "%sy", b);
  point(prefix, x, y, &p->b);
  word(prefix, z, &p->z);
}

/* The opening of slot sum CT by the quorum {1, 2}: the sum, the two parts
   and K = l1 D1 + l2 D2. */
static void open_words(const char *prefix, const ThrShare *shares, const ElgCipher *ct, const U256 *l1, const U256 *l2) {
  ThrPart parts[2];
  G1 q1;
  G1 q2;
  quorum(parts, shares, ct);
  cipher_words(prefix, ct);
  part_words(prefix, "d1", "a1", "b1", "z1", &parts[0]);
  part_words(prefix, "d2", "a2", "b2", "z2", &parts[1]);
  g1_mul(&q1, &parts[0].d, l1);
  g1_mul(&q2, &parts[1].d, l2);
  g1_add(&q1, &q1, &q2);
  point(prefix, "kx", "ky", &q1);
}

/* The polls of examples/resolvekit.lang: deployment = hash(chainId 1,
   receiver), poll 0 = hash(daoTag 3, deployment) and poll 1 (the dispute
   of market 0) = hash(deployment, 0). */
static void poll_ids(U256 *poll0, U256 *poll1) {
  U256 w;
  U256 a;
  U256 d;
  u256_from_u64(&w, 1u);
  u256_from_u64(&a, RECEIVER);
  thr_hash(&d, &w, &a);
  u256_from_u64(&w, 3u);
  thr_hash(poll0, &w, &d);
  u256_from_u64(&a, 0u);
  thr_hash(poll1, &d, &a);
}

/* tweakOf: t = hash(tweakTag 1, ID) mod r. */
static void tweak_of(U256 *t, const U256 *id) {
  U256 w;
  u256_from_u64(&w, 1u);
  thr_hash(t, &w, id);
  mod_r(t);
}

/* nums I: H_p((hash(numsTag 2, I) mod r) G), a slot with no known key. 1,
   or 0 when the hash to point refuses. */
static int nums(G1 *out, uint32_t i) {
  U256 w;
  U256 a;
  U256 h;
  G1 p;
  uint32_t counter = 0;
  u256_from_u64(&w, 2u);
  u256_from_u64(&a, i);
  thr_hash(&h, &w, &a);
  mod_r(&h);
  elg_public(&p, &h);
  return blsag_hash_point(out, &counter, &p);
}

/* One poll of the contract: the ring, then the casts of the voters. */
typedef struct {
  U256 id;
  U256 tweak;
  G1 ring[N];
  uint32_t count;
  uint32_t voter[N];
  Ballot b[N];
} Poll;

/* The poll ID with the ring K_v + t G, t = tweakOf(ID), but the slot nums
   STAKED for the member STAKED (N for none), and the casts of the other
   members for the slots CHOICE. 1, or 0 when a step refuses. */
static int poll_of(Poll *p, const G1 *base, const G1 *pk, const U256 *id, uint32_t staked, const uint32_t *choice) {
  G1 tg;
  uint32_t v;
  p->id = *id;
  tweak_of(&p->tweak, id);
  elg_public(&tg, &p->tweak);
  for (v = 0; v < N; v++)
    g1_add(&p->ring[v], &base[v], &tg);
  if (staked < N && !nums(&p->ring[staked], staked))
    return 0;
  p->count = 0;
  for (v = 0; v < N; v++)
    if (v != staked) {
      p->voter[p->count] = v;
      if (!cast(&p->b[p->count], p->ring, pk, &p->id, &p->tweak, v, choice[v]))
        return 0;
      p->count++;
    }
  return 1;
}

/* T1, the slot 1 sum of the first COUNT casts of P. */
static void t1_of(ElgCipher *out, const Poll *p, uint32_t count) {
  uint32_t i;
  *out = p->b[0].cts[1];
  for (i = 1; i < count; i++)
    elg_add(out, out, &p->b[i].cts[1]);
}

/* 1 when the quorum {1, 2} opens T1 of the first COUNT casts of P to WANT. */
static int t1_count(const Poll *p, const ThrShare *shares, uint32_t count, uint64_t want) {
  ThrPart parts[2];
  G1 keys[N];
  ElgCipher t;
  uint64_t m = 0;
  uint32_t v;
  for (v = 0; v < N; v++)
    keys[v] = shares[v].key;
  t1_of(&t, p, count);
  quorum(parts, shares, &t);
  return thr_open(&m, parts, 2u, keys, T, N, &t, BITS) == THR_FOUND && m == want;
}

/* The words of ballot B with the prefix P: ix, iy, c1, s1 .. s3 (castSig),
   the slots j0 and j1 (castSlot), then the sum proof (castSeal). */
static void ballot_words(const char *p, const Ballot *b) {
  char s[16];
  word(p, "ix", &b->sig[N + 1u]);
  word(p, "iy", &b->sig[N + 2u]);
  word(p, "c1", &b->sig[0]);
  word(p, "s1", &b->sig[1]);
  word(p, "s2", &b->sig[2]);
  word(p, "s3", &b->sig[3]);
  snprintf(s, sizeof s, "%sj0", p);
  slot_words(s, &b->cts[0], &b->slots[0]);
  snprintf(s, sizeof s, "%sj1", p);
  slot_words(s, &b->cts[1], &b->slots[1]);
  snprintf(s, sizeof s, "%ssum", p);
  point(s, "ax", "ay", &b->sum.a);
  point(s, "bx", "by", &b->sum.b);
  word(s, "z", &b->sum.z);
}

/* The opening words of T1 of the first COUNT casts of P (openTally), with
   the prefix PREFIX and the count WANT as the word n. */
static void t1_words(const char *prefix, const Poll *p, const ThrShare *shares, uint32_t count, uint64_t want, const U256 *l1, const U256 *l2) {
  ElgCipher t;
  U256 n;
  t1_of(&t, p, count);
  open_words(prefix, shares, &t, l1, l2);
  u256_from_u64(&n, want);
  word(prefix, "n", &n);
}

/* The words of poll P with the prefix Q: the id, the ring slots r0 .. r2,
   then the ballots b<voter>. */
static void poll_words(const char *q, const Poll *p) {
  char s[16];
  char x[8];
  char y[8];
  uint32_t v;
  word(q, "id", &p->id);
  for (v = 0; v < N; v++) {
    snprintf(x, sizeof x, "r%ux", v);
    snprintf(y, sizeof y, "r%uy", v);
    point(q, x, y, &p->ring[v]);
  }
  for (v = 0; v < p->count; v++) {
    snprintf(s, sizeof s, "%sb%u", q, p->voter[v]);
    ballot_words(s, &p->b[v]);
  }
}

/* `ballottool contract`: poll 0 (prefix q0) has the ring K_v + t0 G and the
   casts of voters 0, 1 and 2 (slots 1, 1, 0): q0t1 opens T1 to 2 of 3 (a
   pass). Member 1 has a stake in market 0, thus poll 1 (prefix q1) has the
   ring K_0 + t1 G, nums 1, K_2 + t1 G and the casts of voters 0 and 2
   (slots 1, 0): q1t1 opens T1 to 1 of 2 (a tie), and q1w1 opens T1 of the
   cast of voter 0 only to 1 of 1 (a pass). The ballot q1ab1 is the cast of
   member 1 (a1) in poll 1 over the ring with no mask, K_v + t1 G (S8 s2,
   Q-S8-3 (a)): the contract must refuse it. The regressions come first: each
   cast verifies in its poll and not in the other poll, q1ab1 verifies over
   the ring with no mask and not over the ring of poll 1, and each T1 opens to
   its count. PRINT 1 prints the words. 1, or 0 when a step fails. */
static int contract(const G1 *pk, const G1 *base, const ThrShare *shares, int print) {
  static const uint32_t choice0[N] = {1u, 1u, 0u};
  static const uint32_t choice1[N] = {1u, 0u, 0u};
  static Poll p[3];
  ThrPart parts[2];
  ElgCipher t;
  U256 id0;
  U256 id1;
  U256 l1;
  U256 l2;
  uint32_t q;
  uint32_t v;
  int ok = 1;
  poll_ids(&id0, &id1);
  if (!poll_of(&p[0], base, pk, &id0, N, choice0) || !poll_of(&p[1], base, pk, &id1, 1u, choice1)
      || !poll_of(&p[2], base, pk, &id1, N, choice1))
    return fail("contract casts");
  for (q = 0; q < 2u; q++)
    for (v = 0; v < p[q].count; v++)
      ok &= blsag_verify(p[q].ring, N, &p[q].id, &p[q].b[v].digest, p[q].b[v].sig) == BLSAG_ACCEPT || fail("contract cast");
  ok &= (blsag_verify(p[1].ring, N, &p[1].id, &p[0].b[0].digest, p[0].b[0].sig) == BLSAG_REJECT
         && blsag_verify(p[0].ring, N, &p[0].id, &p[1].b[0].digest, p[1].b[0].sig) == BLSAG_REJECT)
        || fail("contract cast at the other poll");
  ok &= (blsag_verify(p[2].ring, N, &p[2].id, &p[2].b[1].digest, p[2].b[1].sig) == BLSAG_ACCEPT
         && blsag_verify(p[1].ring, N, &p[1].id, &p[2].b[1].digest, p[2].b[1].sig) == BLSAG_REJECT)
        || fail("contract cast of member 1 over the ring with no mask");
  ok &= (t1_count(&p[0], shares, 3u, 2u) && t1_count(&p[1], shares, 2u, 1u) && t1_count(&p[1], shares, 1u, 1u))
        || fail("contract tally");
  if (!ok || !print)
    return ok;
  t1_of(&t, &p[0], 3u);
  quorum(parts, shares, &t);
  thr_lagrange(&l1, parts, 2u, 0u);
  thr_lagrange(&l2, parts, 2u, 1u);
  point("", "pkx", "pky", pk);
  point("", "p0x", "p0y", &base[0]);
  point("", "p1x", "p1y", &base[1]);
  point("", "p2x", "p2y", &base[2]);
  point("", "k1x", "k1y", &shares[0].key);
  point("", "k2x", "k2y", &shares[1].key);
  word("", "l1", &l1);
  word("", "l2", &l2);
  poll_words("q0", &p[0]);
  t1_words("q0t1", &p[0], shares, 3u, 2u, &l1, &l2);
  poll_words("q1", &p[1]);
  t1_words("q1t1", &p[1], shares, 2u, 1u, &l1, &l2);
  t1_words("q1w1", &p[1], shares, 1u, 1u, &l1, &l2);
  ballot_words("q1ab1", &p[2].b[1]);
  return 1;
}

static void words(const G1 *pk, const G1 *base, const ThrShare *shares, const Ballot *b) {
  ElgCipher left;
  ElgCipher right;
  ThrPart parts[2];
  U256 l1;
  U256 l2;
  slot_sum(&left, b, 0u);
  slot_sum(&right, b, 1u);
  quorum(parts, shares, &left);
  thr_lagrange(&l1, parts, 2u, 0u);
  thr_lagrange(&l2, parts, 2u, 1u);
  point("", "pkx", "pky", pk);
  point("", "p0x", "p0y", &base[0]);
  point("", "p1x", "p1y", &base[1]);
  point("", "p2x", "p2y", &base[2]);
  point("", "k1x", "k1y", &shares[0].key);
  point("", "k2x", "k2y", &shares[1].key);
  word("", "b0ix", &b[0].sig[N + 1u]);
  word("", "b0iy", &b[0].sig[N + 2u]);
  word("", "b0ctx", &b[0].ctx);
  word("", "b0digest", &b[0].digest);
  word("", "b0c1", &b[0].sig[0]);
  word("", "b0s1", &b[0].sig[1]);
  word("", "b0s2", &b[0].sig[2]);
  word("", "b0s3", &b[0].sig[3]);
  slot_words("b0j0", &b[0].cts[0], &b[0].slots[0]);
  slot_words("b0j1", &b[0].cts[1], &b[0].slots[1]);
  point("b0sum", "ax", "ay", &b[0].sum.a);
  point("b0sum", "bx", "by", &b[0].sum.b);
  word("b0sum", "z", &b[0].sum.z);
  word("", "b1ix", &b[1].sig[N + 1u]);
  word("", "b1iy", &b[1].sig[N + 2u]);
  cipher_words("b1j0", &b[1].cts[0]);
  cipher_words("b1j1", &b[1].cts[1]);
  cipher_words("b2j0", &b[2].cts[0]);
  cipher_words("b2j1", &b[2].cts[1]);
  word("", "l1", &l1);
  word("", "l2", &l2);
  open_words("tl", shares, &left, &l1, &l2);
  open_words("tr", shares, &right, &l1, &l2);
}

int main(int argc, char **argv) {
  static const uint32_t choice[3] = {1u, 1u, 0u};
  Ballot b[3];
  ThrShare shares[N];
  ThrPart parts[2];
  G1 ring[N];
  G1 base[N];
  G1 tg;
  G1 keys[N];
  G1 pk;
  U256 sk;
  U256 seed;
  U256 poll;
  U256 tweak;
  U256 x;
  U256 copied;
  U256 tampered;
  ElgCipher left;
  ElgCipher right;
  char text[67];
  uint64_t m_left = 0;
  uint64_t m_right = 0;
  uint32_t v;
  int ok = 1;
  blsag_key(&sk, 5u);
  blsag_key(&seed, 17u);
  if (!thr_deal(shares, &pk, &sk, &seed, T, N)) {
    fputs("FAIL ballot: the deal refuses\n", stderr);
    return 1;
  }
  /* The dispute id replaces poll 0, and the ring is K_i + t G. */
  dispute_of(&poll, &tweak);
  elg_public(&tg, &tweak);
  for (v = 0; v < N; v++) {
    blsag_key(&x, v);
    elg_public(&base[v], &x);
    g1_add(&ring[v], &base[v], &tg);
    keys[v] = shares[v].key;
  }
  for (v = 0; v < 3u; v++)
    if (!cast(&b[v], ring, &pk, &poll, &tweak, v, choice[v])) {
      fprintf(stderr, "FAIL ballot: the cast of voter %u refuses\n", v);
      return 1;
    }
  if (argc == 2 && strcmp(argv[1], "words") == 0) {
    words(&pk, base, shares, b);
    return 0;
  }
  if (argc == 2 && strcmp(argv[1], "contract") == 0)
    return !contract(&pk, base, shares, 1);
  /* The ctx binding: voter 0's ctx is the pinned word and the ballot
     verifies under it. */
  hex(text, sizeof text, &b[0].ctx);
  ok &= (strcmp(text, CTX0) == 0 && sig_onehot_verify(b[0].cts, b[0].slots, &b[0].sum, &pk, K, &b[0].ctx) == SIG_OK)
        || fail("ctx binding");
  /* The digest signature: each ring signature verifies over its own
     digest, and voter 0's signature over the digest of voter 1's slots
     does not. */
  ballot_digest(&tampered, b[1].cts);
  ok &= (blsag_verify(ring, N, &poll, &b[0].digest, b[0].sig) == BLSAG_ACCEPT
         && blsag_verify(ring, N, &poll, &b[1].digest, b[1].sig) == BLSAG_ACCEPT
         && blsag_verify(ring, N, &poll, &b[2].digest, b[2].sig) == BLSAG_ACCEPT
         && blsag_verify(ring, N, &poll, &tampered, b[0].sig) == BLSAG_REJECT)
        || fail("digest signature");
  /* A copy of voter 0's slots and proofs under voter 1's key image. */
  ballot_ctx(&copied, &b[1].sig[N + 1u], &b[1].sig[N + 2u], &poll);
  ok &= sig_onehot_verify(b[0].cts, b[0].slots, &b[0].sum, &pk, K, &copied) == SIG_BAD_SLOT || fail("copy under a second key image");
  /* The tally: the quorum {1, 2} opens the slot sums to (1, 2). */
  slot_sum(&left, b, 0u);
  slot_sum(&right, b, 1u);
  quorum(parts, shares, &left);
  ok &= (thr_open(&m_left, parts, 2u, keys, T, N, &left, BITS) == THR_FOUND && m_left == 1u) || fail("tally left");
  quorum(parts, shares, &right);
  ok &= (thr_open(&m_right, parts, 2u, keys, T, N, &right, BITS) == THR_FOUND && m_right == 2u) || fail("tally right");
  if (!ok)
    return 1;
  puts("ballot regressions: passed");
  if (!contract(&pk, base, shares, 0))
    return 1;
  puts("contract regressions: passed");
  return 0;
}
