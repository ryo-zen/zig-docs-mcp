# Zig Documentation MCP Server

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

### Claude Desktop

Add this server to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "zig-docs": {
      "command": "node",
      "args": ["/absolute/path/to/zig-docs-mcp/build/index.js"],
      "cwd": "/absolute/path/to/zig-docs-mcp"
    }
  }
}
```

**Important:**
- Replace `/absolute/path/to/zig-docs-mcp` with the actual absolute path
- Ensure you've run `npm run build` before starting the server
- Restart Claude Desktop after updating the config

### Claude Code (CLI)

```bash
# Build first
npm run build

# Add server (user scope)
claude mcp add -s user zig-docs -- bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"

# Verify
claude mcp list
```

### Codex CLI

```bash
# Build first
npm run build

# Add server
codex mcp add zig-docs -- bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"

# Verify
codex mcp list
```

### Gemini CLI

```bash
# Build first
npm run build

# Add server (user scope, stdio transport)
gemini mcp add --scope user --transport stdio zig-docs bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"

# Verify
gemini mcp list
```

### OpenCode CLI

```bash
# Build first
npm run build

# Add server (interactive wizard)
opencode mcp add

# Verify
opencode mcp list
```

When prompted in `opencode mcp add`, configure a **stdio** server that runs:

```bash
bash -lc "cd /absolute/path/to/zig-docs-mcp && node build/index.js"
```

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
