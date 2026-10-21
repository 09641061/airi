# Go + Gin Configuration (Koanf + YAML)

## Go + Gin Configuration (Koanf + YAML)

This is the Go equivalent of configuring Spring Boot with `application.yml`: **YAML provides defaults; environment variables override them; Go reads a typed `Config` struct.** Koanf is a configuration library, **not** a dependency-injection framework.

### A. Where does `main.go` go?

- `cmd/api/main.go`: starts the process, loads configuration, opens PostgreSQL, registers Gin routes, and handles shutdown.
- `internal/platform/config/config.go`: loads YAML and environment overrides with Koanf.
- `internal/platform/postgres/pool.go`: creates the PostgreSQL connection pool.
- `internal/bootstrap/`: wires repositories, services, ACL facades, and controllers.
- `config/application.yml`: base settings, like Spring's YAML configuration.

No full project tree is required to understand the guide. Each bounded context keeps the paths defined in sections 1–14.

### B. YAML configuration

File: `config/application.yml`

```yaml
server:
  address: ":8080"

database:
  url: ""           # Set via APP_DATABASE_URL (secret)
  max_conns: 20

gin:
  mode: release
```

Example environment overrides:

```bash
export APP_DATABASE_URL='postgres://<user>:<password>@<host>:5432/<db>?sslmode=require'
export APP_SERVER_ADDRESS=':9090'         # optional override
export APP_DATABASE_MAX_CONNS='30'        # optional override
export APP_GIN_MODE='debug'               # local development only
```

**Priority:** environment variables > `config/application.yml`. Never commit real passwords to YAML or source control. For production, inject secrets using your deployment platform.

### C. Load YAML with Koanf

File: `internal/platform/config/config.go`

```go
package config

import (
    "errors"
    "fmt"
    "os"

    "github.com/knadh/koanf/v2"
    "github.com/knadh/koanf/parsers/yaml"
    "github.com/knadh/koanf/providers/env/v2"
    "github.com/knadh/koanf/providers/file"
)

type Config struct {
    Server struct {
        Address string `koanf:"address"`
    } `koanf:"server"`
    Database struct {
        URL      string `koanf:"url"`
        MaxConns int32  `koanf:"max_conns"`
    } `koanf:"database"`
    Gin struct {
        Mode string `koanf:"mode"`
    } `koanf:"gin"`
}

func Load() (Config, error) {
    k := koanf.New(".")

    path := os.Getenv("APP_CONFIG_FILE")
    if path == "" {
        path = "config/application.yml"
    }
    if err := k.Load(file.Provider(path), yaml.Parser()); err != nil {
        return Config{}, fmt.Errorf("load YAML config: %w", err)
    }

    // Only these APP_* variables override YAML keys.
    if err := k.Load(env.Provider(".", env.Opt{
        Prefix: "APP_",
        TransformFunc: func(key, value string) (string, any) {
            switch key {
            case "APP_SERVER_ADDRESS":
                return "server.address", value
            case "APP_DATABASE_URL":
                return "database.url", value
            case "APP_DATABASE_MAX_CONNS":
                return "database.max_conns", value
            case "APP_GIN_MODE":
                return "gin.mode", value
            default:
                return "", nil
            }
        },
    }), nil); err != nil {
        return Config{}, fmt.Errorf("load env config: %w", err)
    }

    var cfg Config
    if err := k.Unmarshal("", &cfg); err != nil {
        return Config{}, fmt.Errorf("decode config: %w", err)
    }
    if cfg.Server.Address == "" || cfg.Database.URL == "" || cfg.Database.MaxConns < 1 {
        return Config{}, errors.New("invalid server/database configuration")
    }
    if cfg.Gin.Mode != "debug" && cfg.Gin.Mode != "release" && cfg.Gin.Mode != "test" {
        return Config{}, errors.New("invalid gin.mode")
    }
    return cfg, nil
}
```

The YAML parser reads nested keys such as `database.max_conns`; Koanf merges the environment overrides afterward. A configuration is validated **at startup**, not inside domain logic.

Install the packages:

```bash
go get github.com/gin-gonic/gin github.com/jackc/pgx/v5/pgxpool
go get github.com/knadh/koanf/v2 github.com/knadh/koanf/parsers/yaml
go get github.com/knadh/koanf/providers/file github.com/knadh/koanf/providers/env/v2
```

### D. Connect PostgreSQL

File: `internal/platform/postgres/pool.go`

```go
package postgres

import (
    "context"
    "fmt"

    "github.com/jackc/pgx/v5/pgxpool"
)

func NewPool(ctx context.Context, url string, maxConns int32) (*pgxpool.Pool, error) {
    cfg, err := pgxpool.ParseConfig(url)
    if err != nil {
        return nil, fmt.Errorf("invalid PostgreSQL URL: %w", err)
    }
    cfg.MaxConns = maxConns

    pool, err := pgxpool.NewWithConfig(ctx, cfg)
    if err != nil {
        return nil, err
    }
    if err := pool.Ping(ctx); err != nil {
        pool.Close()
        return nil, fmt.Errorf("connect PostgreSQL: %w", err)
    }
    return pool, nil
}
```

The pool belongs to the application lifecycle, **not** to each HTTP request. Close it during shutdown. Apply migrations separately with `goose`.

### E. Start Gin and wire dependencies

In `cmd/api/main.go`, perform these steps in order:

```text
1. cfg, err := config.Load()
2. gin.SetMode(cfg.Gin.Mode)
3. pool, err := postgres.NewPool(ctx, cfg.Database.URL, cfg.Database.MaxConns)
4. defer pool.Close()
5. router := gin.New(); router.Use(gin.Recovery())
6. bootstrap.RegisterRoutes(router, pool, cfg)  // composition root; define for your project
7. Start an http.Server with configured address/timeouts.
8. On SIGINT/SIGTERM, shut down the server gracefully.
```

`bootstrap` creates each **concrete infrastructure repository**, injects it into command/query services **as the corresponding `domain/repositories` interface**, and then wires ACL facades and Gin controllers. Only `bootstrap` knows both the domain contracts and PostgreSQL adapters. Use an `http.Server` for timeout/shutdown control rather than calling `router.Run()` directly in a production service.

### F. Production checks

- [ ] YAML is version-controlled **without secrets**.
- [ ] Koanf loads YAML, then applies environment overrides.
- [ ] A typed config is validated before server startup.
- [ ] `main.go` stays small and delegates wiring to `bootstrap`.
- [ ] One PostgreSQL pool is initialized and closed cleanly.
- [ ] Repository interfaces live in domain; PostgreSQL implementations live in infrastructure.
- [ ] Application services receive repository interfaces, not concrete adapters.
- [ ] Gin remains in REST interfaces, not domain/application.
- [ ] HTTP timeouts, migrations, tracing, and shutdown are configured.

## Technology references

- Koanf: https://github.com/knadh/koanf
- Koanf `env/v2`: https://pkg.go.dev/github.com/knadh/koanf/providers/env/v2
- Gin: https://gin-gonic.com/en/docs/
- pgxpool: https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool
- Go package layout: https://go.dev/doc/modules/layout
