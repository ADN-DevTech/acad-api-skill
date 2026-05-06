# acad-api-skill test scripts

| Script | Purpose |
|--------|---------|
| `run-smoke.ps1` | Runs **install-only** checks for Claude, Composer (Cursor Agent CLI), and Ollama paths. No API tokens. |
| `test-claude.ps1` | Full E2E with **Claude Code** CLI (`claude --print`). |
| `test-composer.ps1` | Full E2E with **Cursor Agent** CLI (`cursor-agent --print --trust --yolo`). |
| `test-ollama.ps1` | A/B baseline vs skills-in-prompt using **local Ollama** HTTP API. |

## Non-interactive / CI

Use `-NonInteractive` so scripts never block on `Read-Host`. Set `ACAD_HOME` or rely on the default `C:\Program Files\Autodesk\AutoCAD 2027` where noted.

```powershell
cd <repo-root>
.\tests\run-smoke.ps1
```

## Full agent runs

Requires a logged-in Cursor account for `cursor-agent` (`cursor-agent whoami`) and Claude billing/limits for `claude`.

```powershell
$env:ACAD_HOME = 'D:\Your\AutoCAD 2027'
.\tests\test-composer.ps1 -NonInteractive -Model "sonnet-4"
.\tests\test-claude.ps1 -NonInteractive
```

## Outputs

Each run creates a timestamped folder under `tests/test-<date>-*` with copied skills, build logs (when applicable), and `_raw_response.txt` / `_cursor_agent.log` for debugging.
