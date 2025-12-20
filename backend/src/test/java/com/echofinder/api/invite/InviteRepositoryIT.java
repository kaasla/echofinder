package com.echofinder.api.invite;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.echofinder.api.user.User;
import com.echofinder.api.user.UserRepository;
import com.echofinder.api.user.UserRole;
import com.echofinder.api.user.UserStatus;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class InviteRepositoryIT {

  @Autowired private InviteRepository inviteRepository;
  @Autowired private UserRepository userRepository;

  private User inviter;

  @BeforeEach
  void setUp() {
    inviter = new User(UUID.randomUUID(), "inviter@example.com", UserRole.ADMIN, UserStatus.ACTIVE);
    userRepository.save(inviter);
  }

  @Test
  void canPersistAndRetrieveInvite() {
    OffsetDateTime expiresAt = OffsetDateTime.now().plusDays(7);
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "invitee@example.com",
            "hashed-token-value",
            UserRole.USER,
            inviter,
            expiresAt);

    Invite saved = inviteRepository.save(invite);

    assertThat(saved.getId()).isNotNull();
    assertThat(saved.getCreatedAt()).isNotNull();

    Optional<Invite> found = inviteRepository.findById(saved.getId());
    assertThat(found).isPresent();
    assertThat(found.get().getEmail()).isEqualTo("invitee@example.com");
    assertThat(found.get().getTokenHash()).isEqualTo("hashed-token-value");
    assertThat(found.get().getInvitedRole()).isEqualTo(UserRole.USER);
    assertThat(found.get().getInviter().getId()).isEqualTo(inviter.getId());
  }

  @Test
  void canFindByTokenHash() {
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "lookup@example.com",
            "unique-hash-for-lookup",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().plusDays(7));
    inviteRepository.save(invite);

    Optional<Invite> found = inviteRepository.findByTokenHash("unique-hash-for-lookup");

    assertThat(found).isPresent();
    assertThat(found.get().getEmail()).isEqualTo("lookup@example.com");
  }

  @Test
  void tokenHashMustBeUnique() {
    Invite invite1 =
        new Invite(
            UUID.randomUUID(),
            "first@example.com",
            "same-hash",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().plusDays(7));
    inviteRepository.saveAndFlush(invite1);

    Invite invite2 =
        new Invite(
            UUID.randomUUID(),
            "second@example.com",
            "same-hash",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().plusDays(7));

    assertThatThrownBy(() -> inviteRepository.saveAndFlush(invite2))
        .isInstanceOf(DataIntegrityViolationException.class);
  }

  @Test
  void isValidReturnsTrueForValidInvite() {
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "valid@example.com",
            "valid-hash",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().plusDays(7));

    assertThat(invite.isValid()).isTrue();
  }

  @Test
  void isValidReturnsFalseForExpiredInvite() {
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "expired@example.com",
            "expired-hash",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().minusDays(1));

    assertThat(invite.isValid()).isFalse();
  }

  @Test
  void isValidReturnsFalseForUsedInvite() {
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "used@example.com",
            "used-hash",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().plusDays(7));
    invite.setUsedAt(OffsetDateTime.now());

    assertThat(invite.isValid()).isFalse();
  }

  @Test
  void isValidReturnsFalseForRevokedInvite() {
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "revoked@example.com",
            "revoked-hash",
            UserRole.USER,
            inviter,
            OffsetDateTime.now().plusDays(7));
    invite.setRevokedAt(OffsetDateTime.now());

    assertThat(invite.isValid()).isFalse();
  }

  @Test
  void canPersistAdminInvite() {
    Invite invite =
        new Invite(
            UUID.randomUUID(),
            "admin-invite@example.com",
            "admin-hash",
            UserRole.ADMIN,
            inviter,
            OffsetDateTime.now().plusDays(7));
    Invite saved = inviteRepository.save(invite);

    assertThat(saved.getInvitedRole()).isEqualTo(UserRole.ADMIN);
  }
}
