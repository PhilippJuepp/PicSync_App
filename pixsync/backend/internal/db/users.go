package db

import (
	"database/sql"
	"errors"
)

type User struct {
	ID int64
	Name string
	Email string
	PasswordHash string
	CreatedAt string
}

func (p *Postgres) CreateUser(name, email, passwordHash string) (int64, error) {
    var id int64
    err := p.DB.QueryRow(
        "INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id",
        name, email, passwordHash,
    ).Scan(&id)
    if err != nil {
        return 0, err
    }
    return id, nil
}

func (p *Postgres) GetUserByEmail(email string) (*User, error) {
    u := &User{}
    row := p.DB.QueryRow(
        "SELECT id, name, email, password_hash, created_at FROM users WHERE LOWER(email) = LOWER($1)",
        email,
    )

    if err := row.Scan(&u.ID, &u.Name, &u.Email, &u.PasswordHash, &u.CreatedAt); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, nil
        }
        return nil, err
    }
    return u, nil
}

func (p *Postgres) GetUserByName(name string) (*User, error) {
    u := &User{}
    row := p.DB.QueryRow(
        "SELECT id, name, email, password_hash, created_at FROM users WHERE LOWER(name) = LOWER($1)",
        name,
    )

    if err := row.Scan(&u.ID, &u.Name, &u.Email, &u.PasswordHash, &u.CreatedAt); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, nil
        }
        return nil, err
    }
    return u, nil
}