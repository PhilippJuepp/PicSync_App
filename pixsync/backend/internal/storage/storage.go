package storage

import (
	"context"
	"errors"
	"io"

	"backend/internal/config"
)

// Storage is the minimal interface PixSync uses to store and retrieve blobs.
// Methods are designed for streaming (no large buffering).
type Storage interface {
	// Put writes the data from src to objectKey. size is the total byte size if known, -1 if unknown.
	// Implementations should write atomically (temp file + rename) where possible.
	Put(ctx context.Context, objectKey string, src io.Reader, size int64) error

	// Get returns a ReadCloser for the stored object. Caller must Close().
	Get(ctx context.Context, objectKey string) (io.ReadCloser, error)

	// Exists checks whether an object key already exists in storage.
	Exists(ctx context.Context, objectKey string) (bool, error)

	// Remove deletes the object.
	Remove(ctx context.Context, objectKey string) error
}

// ErrNotFound is returned when a requested object is not present.
var ErrNotFound = errors.New("object not found")

// New creates a Storage implementation based on cfg.StorageDriver.
// Supported drivers: "local", "minio".
func New(cfg *config.Config) (Storage, error) {
	switch cfg.StorageDriver {
	case "local", "":
		return NewLocal(cfg.LocalStoragePath)
	case "minio":
		return NewMinio(cfg)
	default:
		return nil, errors.New("unsupported storage driver: " + cfg.StorageDriver)
	}
}