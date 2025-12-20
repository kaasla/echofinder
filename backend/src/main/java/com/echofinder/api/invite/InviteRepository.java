package com.echofinder.api.invite;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InviteRepository extends JpaRepository<Invite, UUID> {

  Optional<Invite> findByTokenHash(String tokenHash);
}
