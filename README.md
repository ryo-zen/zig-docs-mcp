# Zig Documentation MCP Server

MCP server providing comprehensive access to Zig language documentation, standard library references, and working code examples.

## Setup

```bash
npm install
```

## Running

```bash
npm start
# or
node zig-mcp-server.js
```

## Features

### Resources
The server exposes three types of resources:
- **Language Documentation** (`zig://doc/*`) - Zig language features, syntax, and concepts
- **Standard Library** (`zig://std/*`) - Type and namespace documentation
- **Working Examples** (`zig://examples/*`) - Runnable Zig code examples

### Tools
- `search_zig_docs` - Search across all documentation with smart scoring
- `get_builtin_info` - Get details about builtin functions (e.g., @import, @sizeof)
- `explain_concept` - Get explanations of Zig concepts (comptime, defer, optionals, etc.)
- `get_syntax_examples` - Get code examples for language constructs
- `get_example` - Retrieve working code examples by topic

## Documentation Structure

- `zig_docs/` - Language documentation (syntax, features, concepts)
- `zig_docs_std/` - Standard library documentation
  - `Types/` - Type documentation (ArrayList, ArrayHashMap, etc.)
  - `Examples/` - Working Zig code examples (50+ examples)
- `templates/` - Documentation templates

## Working Examples

The server includes 50+ working Zig examples covering:
- Data structures (ArrayList, ArrayHashMap)
- I/O operations (Reader, Writer)
- JSON parsing and serialization
- Async/await patterns
- File operations
- And more

Access examples via:
- Resources: `zig://examples/arraylist`, `zig://examples/json_parser`, etc.
- Tool: `get_example("arraylist")`

See CLAUDE.md and STRUCTURE_GUIDE.md for detailed information.
