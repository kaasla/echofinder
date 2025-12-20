package com.echofinder.api.invite;

import com.echofinder.api.user.User;
import com.echofinder.api.user.UserRole;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "invites")
public class Invite {

  @Id private UUID id;

  @Column(nullable = false)
  private String email;

  @Column(name = "token_hash", nullable = false, unique = true)
  private String tokenHash;

  @Enumerated(EnumType.STRING)
  @Column(name = "invited_role", nullable = false)
  private UserRole invitedRole;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "inviter_user_id", nullable = false)
  private User inviter;

  @Column(name = "expires_at", nullable = false)
  private OffsetDateTime expiresAt;

  @Column(name = "used_at")
  private OffsetDateTime usedAt;

  @Column(name = "revoked_at")
  private OffsetDateTime revokedAt;

  @Column(name = "created_at", nullable = false, updatable = false)
  private OffsetDateTime createdAt;

  protected Invite() {}

  public Invite(
      UUID id,
      String email,
      String tokenHash,
      UserRole invitedRole,
      User inviter,
      OffsetDateTime expiresAt) {
    this.id = id;
    this.email = email;
    this.tokenHash = tokenHash;
    this.invitedRole = invitedRole;
    this.inviter = inviter;
    this.expiresAt = expiresAt;
  }

  @PrePersist
  protected void onCreate() {
    this.createdAt = OffsetDateTime.now();
  }

  public boolean isValid() {
    OffsetDateTime now = OffsetDateTime.now();
    return usedAt == null && revokedAt == null && expiresAt.isAfter(now);
  }

  public UUID getId() {
    return id;
  }

  public void setId(UUID id) {
    this.id = id;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String email) {
    this.email = email;
  }

  public String getTokenHash() {
    return tokenHash;
  }

  public void setTokenHash(String tokenHash) {
    this.tokenHash = tokenHash;
  }

  public UserRole getInvitedRole() {
    return invitedRole;
  }

  public void setInvitedRole(UserRole invitedRole) {
    this.invitedRole = invitedRole;
  }

  public User getInviter() {
    return inviter;
  }

  public void setInviter(User inviter) {
    this.inviter = inviter;
  }

  public OffsetDateTime getExpiresAt() {
    return expiresAt;
  }

  public void setExpiresAt(OffsetDateTime expiresAt) {
    this.expiresAt = expiresAt;
  }

  public OffsetDateTime getUsedAt() {
    return usedAt;
  }

  public void setUsedAt(OffsetDateTime usedAt) {
    this.usedAt = usedAt;
  }

  public OffsetDateTime getRevokedAt() {
    return revokedAt;
  }

  public void setRevokedAt(OffsetDateTime revokedAt) {
    this.revokedAt = revokedAt;
  }

  public OffsetDateTime getCreatedAt() {
    return createdAt;
  }
}
