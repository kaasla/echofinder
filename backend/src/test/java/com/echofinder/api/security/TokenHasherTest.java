package com.echofinder.api.security;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class TokenHasherTest {

  private static final String PREFIX_SALT = "test-prefix-salt";
  private static final String SUFFIX_SALT = "test-suffix-salt";

  @Test
  void hashProducesDeterministicOutput() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);

    String hash1 = hasher.hash("my-token");
    String hash2 = hasher.hash("my-token");

    assertEquals(hash1, hash2);
  }

  @Test
  void hashProducesDifferentOutputForDifferentInputs() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);

    String hash1 = hasher.hash("token-one");
    String hash2 = hasher.hash("token-two");

    assertNotEquals(hash1, hash2);
  }

  @Test
  void hashProducesDifferentOutputWithDifferentPrefixSalt() {
    TokenHasher hasher1 = new TokenHasher("prefix-a", SUFFIX_SALT);
    TokenHasher hasher2 = new TokenHasher("prefix-b", SUFFIX_SALT);

    String hash1 = hasher1.hash("same-token");
    String hash2 = hasher2.hash("same-token");

    assertNotEquals(hash1, hash2);
  }

  @Test
  void hashProducesDifferentOutputWithDifferentSuffixSalt() {
    TokenHasher hasher1 = new TokenHasher(PREFIX_SALT, "suffix-a");
    TokenHasher hasher2 = new TokenHasher(PREFIX_SALT, "suffix-b");

    String hash1 = hasher1.hash("same-token");
    String hash2 = hasher2.hash("same-token");

    assertNotEquals(hash1, hash2);
  }

  @Test
  void hashProducesHexEncodedSha256() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);

    String hash = hasher.hash("test-value");

    // SHA-256 produces 64 hex characters
    assertEquals(64, hash.length());
    assertTrue(hash.matches("^[0-9a-f]+$"));
  }

  @Test
  void verifyReturnsTrueForMatchingToken() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);
    String rawToken = "my-secret-token";
    String storedHash = hasher.hash(rawToken);

    assertTrue(hasher.verify(rawToken, storedHash));
  }

  @Test
  void verifyReturnsFalseForNonMatchingToken() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);
    String storedHash = hasher.hash("original-token");

    assertFalse(hasher.verify("wrong-token", storedHash));
  }

  @Test
  void verifyReturnsFalseForNullRawToken() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);
    String storedHash = hasher.hash("some-token");

    assertFalse(hasher.verify(null, storedHash));
  }

  @Test
  void verifyReturnsFalseForNullStoredHash() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);

    assertFalse(hasher.verify("some-token", null));
  }

  @Test
  void constructorThrowsWhenPrefixSaltIsNull() {
    assertThrows(IllegalArgumentException.class, () -> new TokenHasher(null, SUFFIX_SALT));
  }

  @Test
  void constructorThrowsWhenPrefixSaltIsBlank() {
    assertThrows(IllegalArgumentException.class, () -> new TokenHasher("  ", SUFFIX_SALT));
  }

  @Test
  void constructorThrowsWhenSuffixSaltIsNull() {
    assertThrows(IllegalArgumentException.class, () -> new TokenHasher(PREFIX_SALT, null));
  }

  @Test
  void constructorThrowsWhenSuffixSaltIsBlank() {
    assertThrows(IllegalArgumentException.class, () -> new TokenHasher(PREFIX_SALT, ""));
  }

  @Test
  void hashThrowsWhenValueIsNull() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);

    assertThrows(IllegalArgumentException.class, () -> hasher.hash(null));
  }

  @Test
  void hashThrowsWhenValueIsBlank() {
    TokenHasher hasher = new TokenHasher(PREFIX_SALT, SUFFIX_SALT);

    assertThrows(IllegalArgumentException.class, () -> hasher.hash("   "));
  }
}
