-- name: ListUsers :many
SELECT * FROM users WHERE deleted_at IS NULL;

