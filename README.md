# Zig Documentation MCP Server 0.16

MCP server providing comprehensive access to Zig 0.16 language documentation, standard library references, and working code examples.

**Target Zig Version:** `0.16`

## Quick Start

### Prerequisites
- Node.js 18.x or later
- npm (comes with Node.js)

### Setup & Build

```bash
# Install dependencies
npm install

# Build the TypeScript source
npm run build

# Start the server
npm start
```

The server compiles from TypeScript (`src/index.ts`) to JavaScript (`build/index.js`).

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with UI
npm run test:ui

# Generate coverage report
npm run test:coverage
```

## MCP Integration

### Claude Code (CLI)

```bash
# Build first
npm run build

# Add server (user scope)
claude mcp add -s user zig-docs -- bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"

# Verify
claude mcp list
```

Optional config-file form (`.mcp.json` in your project root):

```json
{
  "mcpServers": {
    "zig-docs": {
      "type": "stdio",
      "command": "bash",
      "args": ["-lc", "cd /absolute/path/to/zig-docs-mcp && node build/index.js"],
      "env": {}
    }
  }
}
```

Optional CLI import of the same JSON entry:

```bash
claude mcp add-json -s user zig-docs '{"type":"stdio","command":"bash","args":["-lc","cd /absolute/path/to/zig-docs-mcp && node build/index.js"],"env":{}}'
```

Scope options:
- `-s user` = global config for your user account.
- `-s project` or `-s local` = repo-scoped config.
- `.mcp.json` = file-based repo-scoped config.

**Important:**
- Replace `/absolute/path/to/zig-docs-mcp` with the actual absolute path
- Ensure you've run `npm run build` before starting the server

### Codex CLI

```bash
# Build first
npm run build

# Add server
codex mcp add zig-docs -- bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"

# Verify
codex mcp list
```

Optional config-file form (`~/.codex/config.toml`):

```toml
[mcp_servers.zig-docs]
command = "bash"
args = ["-lc", "cd /absolute/path/to/zig-docs-mcp && node build/index.js"]
```

Scope notes:
- `codex mcp add` persists server config in `~/.codex/config.toml` (user/global).
- Codex CLI does not currently expose a dedicated `--scope` flag for MCP server add.

### Gemini CLI

```bash
# Build first
npm run build

# Add server (user scope, stdio transport)
gemini mcp add --scope user --transport stdio zig-docs bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"

# Verify
gemini mcp list
```

Optional config-file form (`~/.gemini/settings.json`):

```json
{
  "mcp": {
    "allowed": ["zig-docs"]
  },
  "mcpServers": {
    "zig-docs": {
      "command": "bash",
      "args": ["-lc", "cd /absolute/path/to/zig-docs-mcp && node build/index.js"]
    }
  }
}
```

Scope notes:
- `--scope user` stores config in your user settings (for this machine/user).
- `--scope project` stores config in project scope managed by Gemini CLI.

### OpenCode CLI

```bash
# Build first
npm run build

# Verify
opencode mcp list
```

Preferred setup: add MCP in OpenCode config (`~/.config/opencode/opencode.json` or `~/.config/opencode/opencode.jsonc`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "zig-docs": {
      "type": "local",
      "command": ["bash", "-lc", "cd /absolute/path/to/zig-docs-mcp && node build/index.js"],
      "enabled": true
    }
  }
}
```

Optional environment variables:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "zig-docs": {
      "type": "local",
      "command": ["bash", "-lc", "cd /absolute/path/to/zig-docs-mcp && node build/index.js"],
      "environment": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

OpenCode notes:
- OpenCode loads global config from `~/.config/opencode/config.json`, `~/.config/opencode/opencode.json`, and `~/.config/opencode/opencode.jsonc`.
- MCP server config uses `mcp.<name>` with `type: "local"` or `type: "remote"`.
- If you see `MCP error -32000: Connection closed`, verify `command` is a proper argv array (not a broken quoted string split into bad tokens).

### Notes

- Transport for this server is **stdio**.
- The server must run from the repository root because docs are resolved via `process.cwd()`.
- If you pull new changes, run `npm run build` again before reconnecting.

## Features

### Resources
The server exposes three types of resources:
- **Language Documentation** (`zig://doc/*`) - Zig language features, syntax, and concepts
- **Standard Library** (`zig://std/*`) - Type and namespace documentation
- **Working Examples** (`zig://examples/*`) - Runnable Zig code examples

### Tools
- `search_zig_docs` - Search across all documentation with smart scoring and fuzzy matching
- `get_builtin_info` - Get details about builtin functions (e.g., `@import`, `@sizeof`) with suggestions
- `explain_concept` - Get explanations of Zig concepts (comptime, defer, optionals, etc.)
- `get_syntax_examples` - Get code examples for language constructs
- `get_example` - Retrieve working code examples by topic
- `server_diagnostics` - Get server health, cache stats, and diagnostic information

## Documentation Structure

- `zig_docs/` - Language documentation (syntax, features, concepts)
- `zig_docs_std/` - Standard library documentation
  - `Types/` - Type documentation (ArrayList, ArrayHashMap, etc.)
  - `Examples/` - Working Zig code examples (158 examples)
- `templates/` - Documentation templates

## What's Included

- **72 Language Documentation Files** - Covering Zig language features and migration notes
- **345 Standard Library Docs** - Type and namespace documentation
- **158 Working Code Examples** - Runnable Zig code demonstrating patterns and APIs
- **589 Total Cached Resources** - Loaded into memory at startup

## Working Examples

The server includes 158 working Zig examples covering:
- Data structures (ArrayList, ArrayHashMap)
- I/O operations (Reader, Writer, std.Io)
- JSON parsing and serialization
- Async/await patterns
- File operations
- Network programming
- And more

Access examples via:
- Resources: `zig://examples/arraylist`, `zig://examples/reader`, etc.
- Tool: `get_example("arraylist")`

## Documentation

- **CLAUDE.md** - Comprehensive guide for development and contributing
- **IMPROVEMENTS.md** - Detailed improvement plan and roadmap
- Run `server_diagnostics` tool for real-time server statistics

## Testing

All code is tested with a comprehensive test suite:
- 49 automated tests covering core functionality
- URI parsing and file path resolution
- Search algorithm and scoring
- Error handling and suggestions
- Cache behavior and performance

Run `npm test` to verify everything works.
