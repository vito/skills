---
name: dagger-dev-tests
description: Running and debugging integration tests in the Dagger engine repository. Use when running tests, debugging test failures, or iterating on integration tests in the Dagger codebase.
---

# Dagger Development Tests

## When to use

When running or debugging tests in the Dagger repository.

## Repository layout

The Dagger repo uses a **bare git repo with worktrees**:

```
/home/vito/src/dagger/
├── .bare/              # bare git repo
├── main/               # worktree: main branch
├── interfaces/         # worktree: interfaces branch
├── ...                 # other worktrees
```

Each worktree is a standalone checkout with its own `dagger.json` at
the root. **Always `cd` into the correct worktree before running
commands.** There is no top-level `dagger.json`.

## Running checks

Use `dagger check` to run pre-defined check targets:

```bash
dagger check -l                                  # list all checks
dagger check --progress=dots typescript-sdk:test-bunjs   # run a specific check
dagger check 'typescript-sdk:*'                  # run all checks for a toolchain
```

## Generating code

Use `dagger generate` to regenerate SDK client libraries and other generated code:

```bash
dagger generate -l                          # list all generate targets
dagger generate --progress=dots foo:bar -y  # regenerate a specific target
```

The same `--progress` flag logic applies: use `--progress=dots` by default, `--progress=plain` if you need more detail.

## Running individual engine tests

Use `dagger call` to run individual engine integration tests with `--run`:

```bash
dagger call --progress=dots engine-dev test --run 'TestFoo/TestBar' --pkg ./core/integration/
```

### Rules

1. **Do not use `go test` to run tests.** Always use the `dagger` CLI.
2. **Always pass `--progress=dots`** for succinct output. If it hides too much, switch to `--progress=plain`.
3. **Always redirect output to a tmpfile** — these commands take minutes to run and the output is valuable:
   ```bash
   dagger call --progress=dots engine-dev test --run 'TestFoo' --pkg ./core/integration/ > /tmp/test-output.txt 2>&1
   ```
4. **Use generous timeouts** (300-600s) since engine builds and tests are slow.
5. **After the run**, read/grep the tmpfile for results — don't rely on watching live output.

## Debugging tests

**Add `slog.Warn("!!! FOO_BAR")` lines early and often.** Then grep for them in the output file to find your answers:

```bash
grep '!!! ' /tmp/test-output.txt
```

This is the fastest way to understand control flow and variable values in failing tests. Use descriptive names like `slog.Warn("!!! TERMINAL_CMD_STARTED")`, `slog.Warn("!!! CA_CERT_PATH", "path", certPath)`, etc.

## Tips

- The `--run` flag takes a `/`-separated test path, e.g. `TestContainer/TestSystemCACerts/terminal`
- The `--pkg` flag is relative to the repo root
- If you need to iterate, keep the same tmpfile path and overwrite it each run
- Engine-side `slog.Warn` shows up in the output; CLI-side `slog.Warn` does NOT (it goes through OTel). Use `fmt.Fprintf(os.Stderr, ...)` for CLI-side debug logging.
- Look for `testctx.go:` lines in the output — they contain the TUI output from test subprocesses and often have the real error message buried in ANSI escape codes
