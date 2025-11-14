package db

import (
	"fmt"
)

func (p *Postgres) Migrate() error {
	schema := `
	CREATE EXTENSION IF NOT EXISTS pgcrypto;

	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		name TEXT UNIQUE,
		email TEXT NOT NULL UNIQUE,
		password_hash TEXT NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
	);

	DO $$
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='name') THEN
			ALTER TABLE users ADD COLUMN name TEXT UNIQUE;
		END IF;
	END$$;

	CREATE TABLE IF NOT EXISTS sessions (
		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		refresh_token_hash TEXT NOT NULL,
		device_name TEXT,
		device_id TEXT,
		ip TEXT,
		user_agent TEXT,
		created_at TIMESTAMPTZ DEFAULT now(),
		last_used_at TIMESTAMPTZ DEFAULT now(),
		expires_at TIMESTAMPTZ,
		revoked BOOLEAN DEFAULT FALSE
	);

	CREATE TABLE IF NOT EXISTS assets (
		id SERIAL PRIMARY KEY,
		user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		filename TEXT NOT NULL,
		path TEXT NOT NULL,
		size BIGINT NOT NULL,
		mime TEXT NOT NULL,
		hash TEXT NOT NULL,
		taken_at TIMESTAMP WITH TIME ZONE,
		storage_key TEXT NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
	);

	CREATE TABLE IF NOT EXISTS uploads (
		id TEXT PRIMARY KEY,
		user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
		filename TEXT NOT NULL,
		temp_path TEXT NOT NULL,
		total_size BIGINT NOT NULL,
		uploaded_offset BIGINT DEFAULT 0,
		completed BOOLEAN DEFAULT FALSE,
		mime TEXT,
		taken_at TIMESTAMP WITH TIME ZONE,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
	);

	CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
	CREATE INDEX IF NOT EXISTS idx_sessions_refresh_hash ON sessions(refresh_token_hash);
	`

	if _, err := p.DB.Exec(schema); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	return nil
}