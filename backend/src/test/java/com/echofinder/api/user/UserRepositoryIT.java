package com.echofinder.api.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class UserRepositoryIT {

  @Autowired private UserRepository userRepository;

  @Test
  void canPersistAndRetrieveUser() {
    User user = new User(UUID.randomUUID(), "test@example.com", UserRole.USER, UserStatus.ACTIVE);
    user.setDisplayName("Test User");

    User saved = userRepository.save(user);

    assertThat(saved.getId()).isNotNull();
    assertThat(saved.getCreatedAt()).isNotNull();
    assertThat(saved.getUpdatedAt()).isNotNull();

    Optional<User> found = userRepository.findById(saved.getId());
    assertThat(found).isPresent();
    assertThat(found.get().getEmail()).isEqualTo("test@example.com");
    assertThat(found.get().getDisplayName()).isEqualTo("Test User");
    assertThat(found.get().getRole()).isEqualTo(UserRole.USER);
    assertThat(found.get().getStatus()).isEqualTo(UserStatus.ACTIVE);
  }

  @Test
  void findByEmailIsCaseInsensitive() {
    User user = new User(UUID.randomUUID(), "Test@Example.COM", UserRole.USER, UserStatus.ACTIVE);
    userRepository.save(user);

    Optional<User> found = userRepository.findByEmail("test@example.com");

    assertThat(found).isPresent();
    assertThat(found.get().getEmail()).isEqualTo("Test@Example.COM");
  }

  @Test
  void emailUniquenessIsCaseInsensitive() {
    User user1 =
        new User(UUID.randomUUID(), "unique@example.com", UserRole.USER, UserStatus.ACTIVE);
    userRepository.saveAndFlush(user1);

    User user2 =
        new User(UUID.randomUUID(), "UNIQUE@example.com", UserRole.USER, UserStatus.ACTIVE);

    assertThatThrownBy(() -> userRepository.saveAndFlush(user2))
        .isInstanceOf(DataIntegrityViolationException.class);
  }

  @Test
  void canPersistAdminUser() {
    User admin =
        new User(UUID.randomUUID(), "admin@example.com", UserRole.ADMIN, UserStatus.ACTIVE);
    User saved = userRepository.save(admin);

    assertThat(saved.getRole()).isEqualTo(UserRole.ADMIN);
  }

  @Test
  void canPersistPendingUser() {
    User pending =
        new User(UUID.randomUUID(), "pending@example.com", UserRole.USER, UserStatus.PENDING);
    User saved = userRepository.save(pending);

    assertThat(saved.getStatus()).isEqualTo(UserStatus.PENDING);
  }

  @Test
  void canPersistDisabledUser() {
    User disabled =
        new User(UUID.randomUUID(), "disabled@example.com", UserRole.USER, UserStatus.DISABLED);
    User saved = userRepository.save(disabled);

    assertThat(saved.getStatus()).isEqualTo(UserStatus.DISABLED);
  }
}
