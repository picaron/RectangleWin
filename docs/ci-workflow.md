# GitHub Actions CI Workflow Explanation

This document provides a detailed, line-by-line explanation of the `.github/workflows/ci.yml` file.

---

## 1. License Header (Lines 1-13)

```yaml
# Copyright 2022 Ahmet Alp Balkan
#
# Licensed under the Apache License, Version 2.0 (the "License");
# ...
```

- Apache License 2.0 notice
- Original author: Ahmet Alp Balkan
- Same license header applied to all source files

---

## 2. Workflow Basic Configuration (Lines 15-18)

```yaml
name: RectangleWin
on:
  push:
  pull_request:
```

| Line | Description |
|------|-------------|
| `name: RectangleWin` | Workflow name displayed in the GitHub Actions UI |
| `on:` | Defines workflow trigger conditions |
| `push:` | Runs on push to any branch (no filter) |
| `pull_request:` | Runs on PR creation/update |

**Trigger Events:**
- When code is pushed (all branches)
- When a PR is opened or updated

---

## 3. Job Definition (Lines 19-21)

```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
```

| Line | Description |
|------|-------------|
| `jobs:` | Start defining jobs to run |
| `ci:` | Job ID (name can be freely chosen) |
| `runs-on: ubuntu-latest` | Runs on the latest Ubuntu LTS version |

**Run Environment:**
- Ubuntu virtual machine provided by GitHub
- Starts with a clean environment on every run

---

## 4. Checkout Step (Lines 23-24)

```yaml
    - name: Checkout
      uses: actions/checkout@v4
```

| Item | Description |
|------|-------------|
| **Purpose** | Clone the repository code onto the runner |
| **Action** | `actions/checkout@v4` (official GitHub action) |
| **Behavior** | Performs `git clone` + `git checkout` |

**Why is this needed?**
- GitHub Actions runners start in an empty environment
- Build/testing is impossible without the code

---

## 5. Go Installation (Lines 25-28)

```yaml
    - name: Setup Go
      uses: actions/setup-go@v6
      with:
        go-version: "1.25"
```

| Item | Description |
|------|-------------|
| **Purpose** | Install the Go language environment |
| **Action** | `actions/setup-go@v6` (official GitHub action) |
| **Version** | Installs Go 1.25 |

**Capabilities:**
- Downloads and installs the specified Go version
- Adds Go to the `PATH` environment variable
- Configures `GOPATH`, `GOMODCACHE`, and other environment variables

---

## 6. Cache Path Extraction (Lines 29-32)

```yaml
    - id: go-cache-paths
      run: |
        echo "go-build=$(go env GOCACHE)" >> $GITHUB_OUTPUT
        echo "go-mod=$(go env GOMODCACHE)" >> $GITHUB_OUTPUT
```

| Item | Description |
|------|-------------|
| **Purpose** | Store Go cache directory paths as variables |
| `id: go-cache-paths` | ID for referencing this step |
| `go env GOCACHE` | Go build cache path (compiled artifacts) |
| `go env GOMODCACHE` | Go module cache path (downloaded dependencies) |
| `$GITHUB_OUTPUT` | Stores output values for use in other steps |

**Example Output:**
```
go-build=/home/runner/.cache/go-build
go-mod=/home/runner/go/pkg/mod
```

---

## 7. Build Cache Setup (Lines 33-39)

```yaml
    - name: go build cache
      uses: actions/cache@v4
      with:
        key: ${{ runner.os }}-go-build-${{ hashFiles('**/go.sum') }}
        path: |
          ${{ steps.go-cache-paths.outputs.go-build }}
          ${{ steps.go-cache-paths.outputs.go-mod }}
```

| Item | Description |
|------|-------------|
| **Purpose** | Caching to improve build speed |
| **Action** | `actions/cache@v4` |
| `key` | Cache identifier (OS + go.sum hash) |
| `path` | Directories to cache |

**Cache Key Composition:**
- `runner.os`: Operating system (Linux)
- `hashFiles('**/go.sum')`: Hash of the go.sum file

**How It Works:**
1. Search for existing cache using the cache key
2. If found → Restore cache (fast)
3. If not found → Build fresh and save cache

**Benefits:**
- Saves dependency download time
- Reduces compilation time

---

## 8. Code Format Check (Lines 40-41)

```yaml
    - name: Ensure gofmt
      run: test -z "$(gofmt -s -d .)"
```

| Item | Description |
|------|-------------|
| **Purpose** | Verify compliance with Go formatting rules |
| `gofmt -s -d .` | Checks all Go files in the current directory |
| `-s` | Simplify code |
| `-d` | Output in diff format |
| `test -z "..."` | Succeeds if output is empty (exit 0) |

**Failure Condition:**
- If unformatted code exists, diff output is produced → test fails

**Fix:**
```bash
gofmt -s -w .  # Auto-fix
```

---

## 9. go.mod Tidiness Check (Lines 42-43)

```yaml
    - name: go.mod is tidied
      run: go mod tidy && git diff --no-patch --exit-code
```

| Item | Description |
|------|-------------|
| **Purpose** | Verify go.mod/go.sum are in a tidied state |
| `go mod tidy` | Removes unused dependencies, adds missing ones |
| `git diff --no-patch --exit-code` | Fails if files have been modified |

**Check Logic:**
1. Run `go mod tidy`
2. Check if files were changed
3. Changed → means `go mod tidy` was not run before committing → failure

**Fix:**
```bash
go mod tidy
git add go.mod go.sum
git commit --amend
```

---

## 10. Resource Generation (Lines 44-45)

```yaml
    - name: go generate (Binary Version Information and Icon)
      run: go generate
```

| Item | Description |
|------|-------------|
| **Purpose** | Generate resource files needed for building |
| `go generate` | Executes code with `//go:generate` annotations |

**What this project generates:**
- Windows executable version info (versioninfo)
- Icon resources (.syso file)

**Related Code (main.go):**
```go
//go:generate goversioninfo -icon=assets/icon.ico
```

---

## 11. Snapshot Build (Lines 46-54)

```yaml
    - name: Build-only (GoReleaser)
      if: "!startsWith(github.ref, 'refs/tags/')"
      uses: goreleaser/goreleaser-action@v6
      with:
        distribution: goreleaser
        version: "~> v2"
        args: release --snapshot
      env:
        GORELEASER_SKIP_PUBLISH: true
```

| Item | Description |
|------|-------------|
| **Purpose** | Build test for regular pushes/PRs |
| `if: "!startsWith(...)"` | Runs only when it is **NOT** a tag |
| `--snapshot` | Test build without version |
| `GORELEASER_SKIP_PUBLISH: true` | Does not publish to GitHub Release |

**Condition Analysis:**
- `github.ref`: Current branch/tag reference
- `refs/tags/v1.0.0` format → tag
- `refs/heads/main` format → branch

**Snapshot Build:**
- Validates the build process without an actual release
- Catches build failures early

---

## 12. Release Build (Lines 55-64)

```yaml
    - name: Publish release (GoReleaser)
      if: startsWith(github.ref, 'refs/tags/')
      uses: goreleaser/goreleaser-action@v6
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        GORELEASER_SKIP_PUBLISH: true
      with:
        distribution: goreleaser
        version: "~> v2"
        args: release
```

| Item | Description |
|------|-------------|
| **Purpose** | Actual release build on tag push |
| `if: startsWith(...)` | Runs only when it **IS** a tag |
| `GITHUB_TOKEN` | GitHub API authentication (auto-provided) |
| `args: release` | Performs actual release |

**Trigger Condition:**
```bash
git tag v1.0.0
git push origin v1.0.0  # Executes at this point
```

**Note:** `GORELEASER_SKIP_PUBLISH: true` is set, so it actually does not publish to GitHub Releases (appears to be for testing purposes)

---

## Workflow Flowchart

```
push/PR occurs
    │
    ▼
┌──────────────────────────────────────┐
│  1. Checkout (clone code)            │
│  2. Setup Go (install Go 1.25)       │
│  3. Extract cache paths              │
│  4. Restore/save cache               │
│  5. gofmt check                      │
│  6. go mod tidy check                │
│  7. go generate (resource generation)│
└──────────────────────────────────────┘
    │
    ▼
┌─────────────────┐     ┌──────────────────┐
│  Not a tag?     │ YES │  Snapshot Build  │
│  (regular push) │────▶│  (test purpose)  │
│  /PR            │     │                  │
└─────────────────┘     └──────────────────┘
    │ NO (tag)
    ▼
┌──────────────────┐
│  Release Build   │
│  (actual deploy) │
└──────────────────┘
```

---

## Related Files

- `.github/workflows/ci.yml` - The file described in this document
- `.goreleaser.yaml` - GoReleaser build configuration
- `go.mod` / `go.sum` - Go module dependencies
- `main.go` - Contains `//go:generate` directives