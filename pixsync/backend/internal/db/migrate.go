package db

import (
	"fmt"
)

func (p *Postgres) Migrate() error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
	  id SERIAL PRIMARY KEY,
	  email TEXT NOT NULL UNIQUE,
	  password_hash TEXT NOT NULL,
	  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
	);
	`
	_, err := p.DB.Exec(schema)
	if err != nil {
		return fmt.Errorf("migrate users: %w", err)
	}
	return nil
}