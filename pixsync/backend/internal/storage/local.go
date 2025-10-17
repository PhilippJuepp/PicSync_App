package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// LocalStorage stores objects on the host filesystem under basePath.
// Layout: basePath/<objectKey> (objectKey may contain slashes)
type LocalStorage struct {
	basePath string
}

// NewLocal returns a LocalStorage instance and ensures base path exists.
func NewLocal(basePath string) (*LocalStorage, error) {
	if basePath == "" {
		return nil, fmt.Errorf("local storage basePath is empty")
	}
	if err := os.MkdirAll(basePath, 0o755); err != nil {
		return nil, fmt.Errorf("failed to create base path: %w", err)
	}
	return &LocalStorage{basePath: basePath}, nil
}

func (l *LocalStorage) fullPath(objectKey string) string {
	// Clean objectKey to avoid escaping the base path
	clean := filepath.Clean(objectKey)
	return filepath.Join(l.basePath, clean)
}

// Put writes src to a temporary file and renames it into place for atomicity.
func (l *LocalStorage) Put(ctx context.Context, objectKey string, src io.Reader, size int64) error {
	destPath := l.fullPath(objectKey)
	destDir := filepath.Dir(destPath)

	// ensure directory exists
	if err := os.MkdirAll(destDir, 0o755); err != nil {
		return fmt.Errorf("mkdirall: %w", err)
	}

	// create temp file in same directory for atomic move
	tmpFile, err := os.CreateTemp(destDir, ".tmp-*")
	if err != nil {
		return fmt.Errorf("create temp file: %w", err)
	}
	tmpPath := tmpFile.Name()

	// Ensure cleanup on failure
	defer func() {
		tmpFile.Close()
		_ = os.Remove(tmpPath)
	}()

	// Copy streaming with cancellation support
	// Use io.Copy so it streams and doesn't buffer entire file
	_, err = io.Copy(tmpFile, src)
	if err != nil {
		return fmt.Errorf("write temp file: %w", err)
	}

	// ensure file is flushed to disk
	if err := tmpFile.Sync(); err != nil {
		return fmt.Errorf("sync temp file: %w", err)
	}
	if err := tmpFile.Close(); err != nil {
		return fmt.Errorf("close temp file: %w", err)
	}

	// atomic rename into place
	if err := os.Rename(tmpPath, destPath); err != nil {
		return fmt.Errorf("rename temp file: %w", err)
	}
	return nil
}

// Get opens the file for reading and returns an io.ReadCloser.
func (l *LocalStorage) Get(ctx context.Context, objectKey string) (io.ReadCloser, error) {
	path := l.fullPath(objectKey)
	f, err := os.Open(path)
	if os.IsNotExist(err) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("open file: %w", err)
	}
	return f, nil
}

// Exists checks whether the object file exists.
func (l *LocalStorage) Exists(ctx context.Context, objectKey string) (bool, error) {
	path := l.fullPath(objectKey)
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, fmt.Errorf("stat file: %w", err)
}

// Remove deletes the object file.
func (l *LocalStorage) Remove(ctx context.Context, objectKey string) error {
	path := l.fullPath(objectKey)
	if err := os.Remove(path); err != nil {
		if os.IsNotExist(err) {
			return ErrNotFound
		}
		return fmt.Errorf("remove file: %w", err)
	}
	return nil
}