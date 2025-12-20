package com.echofinder.api.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Utility for hashing non-password tokens (invite tokens, reset tokens, API keys).
 *
 * <p>Uses prefix+value+suffix salting strategy: hash = SHA-256(prefix + value + suffix)
 *
 * <p>Salts are read from environment variables to prevent rainbow table attacks while keeping
 * hashes deterministic for lookup.
 */
@Component
public class TokenHasher {

  private final String prefixSalt;
  private final String suffixSalt;

  public TokenHasher(
      @Value("${echo.hash.prefix-salt}") String prefixSalt,
      @Value("${echo.hash.suffix-salt}") String suffixSalt) {
    if (prefixSalt == null || prefixSalt.isBlank()) {
      throw new IllegalArgumentException("ECHO_HASH_PREFIX_SALT must be configured");
    }
    if (suffixSalt == null || suffixSalt.isBlank()) {
      throw new IllegalArgumentException("ECHO_HASH_SUFFIX_SALT must be configured");
    }
    this.prefixSalt = prefixSalt;
    this.suffixSalt = suffixSalt;
  }

  /**
   * Hashes a token value using prefix+suffix salting.
   *
   * @param value the raw token value to hash
   * @return hex-encoded SHA-256 hash
   * @throws IllegalArgumentException if value is null or blank
   */
  public String hash(String value) {
    if (value == null || value.isBlank()) {
      throw new IllegalArgumentException("Value to hash cannot be null or blank");
    }

    String salted = prefixSalt + value + suffixSalt;

    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hashBytes = digest.digest(salted.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(hashBytes);
    } catch (NoSuchAlgorithmException e) {
      // SHA-256 is guaranteed to be available in all Java implementations
      throw new RuntimeException("SHA-256 algorithm not available", e);
    }
  }

  /**
   * Verifies that a raw token matches a stored hash.
   *
   * @param rawToken the raw token to verify
   * @param storedHash the stored hash to compare against
   * @return true if the hash of rawToken matches storedHash
   */
  public boolean verify(String rawToken, String storedHash) {
    if (rawToken == null || storedHash == null) {
      return false;
    }
    return hash(rawToken).equals(storedHash);
  }
}
