-- V1__users_and_invites.sql
-- Creates the foundational tables for invite-only authentication

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT,
    role TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT users_role_check CHECK (role IN ('USER', 'ADMIN')),
    CONSTRAINT users_status_check CHECK (status IN ('ACTIVE', 'PENDING', 'DISABLED'))
);

-- Unique index on lowercase email for case-insensitive uniqueness
CREATE UNIQUE INDEX idx_users_email_unique ON users(LOWER(email));

-- Index on status for filtering active/pending/disabled users
CREATE INDEX idx_users_status ON users(status);

-- Invites table
CREATE TABLE invites (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    token_hash TEXT NOT NULL,
    invited_role TEXT NOT NULL,
    inviter_user_id UUID NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT invites_token_hash_unique UNIQUE (token_hash),
    CONSTRAINT invites_invited_role_check CHECK (invited_role IN ('USER', 'ADMIN')),
    CONSTRAINT invites_inviter_fk FOREIGN KEY (inviter_user_id) REFERENCES users(id)
);

-- Index on email for looking up invites by recipient
CREATE INDEX idx_invites_email ON invites(email);

-- Index on expires_at for cleanup queries
CREATE INDEX idx_invites_expires_at ON invites(expires_at);