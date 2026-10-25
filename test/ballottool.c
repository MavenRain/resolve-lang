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
   `name 0x<word>` per line (p0 .. p2 are the keys before the tweak). */
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
  return 0;
}
