package main

import (
	"database/sql"
	"embed"
	"errors"
	"go-docker/stores"
	"go-docker/templates"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	_ "github.com/mattn/go-sqlite3"
)

//go:embed "public/*"
var PublicFS embed.FS

func main() {
	addr := MustGetenv("ADDR")
	dsn := MustGetenv("DSN")

	db, err := sql.Open("sqlite3", dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}

	store := stores.New(db)

	mux := chi.NewRouter()

	mux.Use(middleware.Logger)
	mux.Use(middleware.Recoverer)

	mux.Get("/", func(w http.ResponseWriter, r *http.Request) {
		users, err := store.ListUsers(r.Context())
		if err != nil {
			log.Fatal(err)
		}
		log.Printf("users: %v", users)

		templates.Index().Render(r.Context(), w)
	})

	mux.Handle("/public/*", http.FileServer(http.FS(PublicFS)))

	log.Printf("Listening on %s...", addr)
	if err := http.ListenAndServe(addr, mux); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}

	log.Println("Server closed")
}

func MustGetenv(key string) string {
	value, ok := os.LookupEnv(key)
	if !ok {
		log.Fatalf("Env variable %s missing", key)
	}

	return value
}
