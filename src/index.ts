#!/usr/bin/env node

/**
 * Zig Documentation MCP Server - Hierarchical Version
 *
 * This MCP server provides access to the complete Zig 0.16 documentation.
 * Uses dynamic file discovery with hierarchical folder structure.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  CallToolRequestSchema,
  ErrorCode,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { pathToFileURL } from 'url';

// Interface for cached resource items
interface ResourceEntry {
  uri: string;
  name: string;
  description: string;
  mimeType: string;
  _filePath: string;
}

// Interface for search results
interface SearchResult {
  score: number;
  text: string;
}

class ZigDocumentationServer {
  private server: Server;
  private docCache: Map<string, string>;
  private resourceList: ResourceEntry[];
  private readonly serverName = 'zig-documentation-server';
  private readonly serverVersion = '0.5.0';

  // API migration mapping for Zig 0.16 changes
  private readonly apiMigrationMap: Map<string, string> = new Map([
    // Formatting functions (renamed in 0.16)
    ['fmtSliceHexLower', 'hex (use std.fmt.fmtSliceHexLower or fmt.hex)'],
    ['fmtSliceHexUpper', 'hex (use std.fmt.fmtSliceHexUpper or fmt.hex)'],
    ['fmtIntSizeDec', 'formatInt or std.fmt'],
    ['fmtIntSizeBin', 'formatInt or std.fmt'],

    // ArrayList changes (managed → unmanaged)
    ['ArrayList.init', 'ArrayList.empty (0.16 uses unmanaged ArrayList)'],
    ['list.deinit()', 'list.deinit(allocator) (pass allocator in 0.16)'],
    ['list.append(item)', 'list.append(allocator, item) (pass allocator in 0.16)'],

    // MemoryPool changes
    ['MemoryPool.init', 'MemoryPool.empty (0.16 uses unmanaged pools)'],
    ['pool.create()', 'pool.create(allocator) (pass allocator in 0.16)'],

    // Filesystem changes
    ['fs.cwd().openFile', 'See migration_filesystem.md for 0.16 changes'],
    ['Dir.openFile', 'See migration_filesystem.md for new patterns'],

    // Networking changes
    ['net.TcpServer', 'See migration_networking.md for 0.16 Io changes'],
    ['net.StreamServer', 'Use std.Io.Threaded.listen in 0.16'],

    // Time changes
    ['time.timestamp', 'See migration_time.md for 0.16 monotonic time'],
    ['time.milliTimestamp', 'Use std.time.nanoTimestamp() / ns_per_ms in 0.16'],
  ]);

  // Synonym mapping for expanding search queries
  private readonly synonymMap: Map<string, string[]> = new Map([
    // Safety & Validation
    ['checking', ['safety', 'check', 'checks', 'runtime safety', 'validation', 'verify']],
    ['validation', ['safety', 'check', 'verification', 'verify', 'checking']],
    ['overflow', ['overflow', 'wraparound', 'saturating', 'underflow']],

    // Error Handling
    ['error', ['error', 'errors', 'exception', 'failure', 'try', 'catch']],
    ['panic', ['panic', 'crash', 'abort', 'fatal', 'unreachable']],

    // Memory Management
    ['memory', ['memory', 'allocator', 'allocation', 'heap', 'stack']],
    ['allocator', ['allocator', 'malloc', 'free', 'allocation', 'memory', 'gpa']],
    ['pointer', ['pointer', 'ptr', 'address', 'reference']],
    ['slice', ['slice', 'array', 'view', 'span', 'subarray']],

    // Data Structures
    ['array', ['array', 'slice', 'list', 'arraylist', 'vector']],
    ['string', ['string', 'str', 'text', 'bytes', 'buffer']],
    ['hash', ['hash', 'map', 'hashmap', 'dict', 'dictionary', 'table']],
    ['map', ['map', 'hashmap', 'hash', 'dict', 'dictionary', 'table']],

    // Types & Structures
    ['type', ['type', 'struct', 'enum', 'union', 'interface']],
    ['struct', ['struct', 'class', 'object', 'record', 'type']],
    ['enum', ['enum', 'enumeration', 'variant', 'tagged']],
    ['union', ['union', 'tagged union', 'variant', 'sum type', 'adt']],

    // Functions
    ['function', ['function', 'fn', 'method', 'procedure']],
    ['inline', ['inline', 'force inline', 'noinline']],

    // Nullability & Optionals
    ['optional', ['optional', 'null', 'nil', 'maybe', 'none', 'nullable']],
    ['null', ['null', 'nil', 'optional', 'none', 'nullable', 'undefined']],

    // Compile-Time
    ['comptime', ['comptime', 'compiletime', 'static', 'constexpr', 'const']],
    ['const', ['const', 'constant', 'immutable', 'readonly', 'final']],

    // Control Flow
    ['loop', ['loop', 'for', 'while', 'iterate', 'iteration', 'foreach']],
    ['defer', ['defer', 'finally', 'cleanup', 'destructor', 'deinit', 'raii']],
    ['branch', ['branch', 'if', 'conditional', 'switch', 'case']],

    // Concurrency & Threading
    ['async', ['async', 'asynchronous', 'await', 'future', 'promise']],
    ['thread', ['thread', 'concurrent', 'parallel', 'threading', 'multithreading']],
    ['atomic', ['atomic', 'atomics', 'lock', 'mutex', 'sync', 'synchronization']],

    // Compilation & Build
    ['build', ['build', 'compile', 'compilation', 'linking', 'transpile']],
    ['import', ['import', 'include', 'require', 'use', 'module']],

    // Testing
    ['test', ['test', 'testing', 'unittest', 'assert', 'expect']],

    // Casting & Conversion
    ['cast', ['cast', 'casting', 'convert', 'coerce', 'transmute', 'as']],

    // Unsafe & FFI
    ['unsafe', ['unsafe', 'raw', 'unchecked', 'volatile']],
    ['extern', ['extern', 'external', 'foreign', 'ffi', 'c', 'abi']],
    ['builtin', ['builtin', 'intrinsic', 'compiler']],

    // I/O & Formatting
    ['io', ['io', 'input', 'output', 'file', 'stream', 'read', 'write']],
    ['format', ['format', 'fmt', 'print', 'printf', 'sprintf']],

    // Standard Library Namespaces
    ['json', ['json', 'parse', 'serialize', 'deserialize', 'marshal', 'unmarshal']],
    ['crypto', ['crypto', 'hash', 'encrypt', 'decrypt', 'cipher', 'cryptography']],
    ['log', ['log', 'logging', 'debug', 'trace', 'warn', 'info', 'logger']],

    // Common Operations
    ['iterate', ['iterate', 'iteration', 'loop', 'for', 'foreach', 'iterator']],
    ['mutable', ['mutable', 'var', 'variable', 'let']],
  ]);

  constructor() {
    this.server = new Server({
      name: this.serverName,
      version: this.serverVersion,
    }, {
      capabilities: {
        resources: {},
        tools: {},
      },
    });

    // In-memory cache for documentation files
    this.docCache = new Map();
    this.resourceList = [];

    this.setupResourceHandlers();
    this.setupToolHandlers();
  }

  async readMarkdownFile(filename: string): Promise<string> {
    try {
      // Check cache first
      if (this.docCache.has(filename)) {
        return this.docCache.get(filename)!;
      }

      // If not in cache, read from disk (fallback)
      const filePath = path.join(process.cwd(), filename);
      const content = await fs.promises.readFile(filePath, 'utf8');

      // Cache it for next time
      this.docCache.set(filename, content);

      return content;
    } catch (error: any) {
      throw new McpError(
        ErrorCode.InternalError,
        `Failed to read file ${filename}: ${error.message}`
      );
    }
  }

  // Load all documentation files into memory cache at startup
  async loadDocsIntoCache(): Promise<void> {
    const langDocsDir = path.join(process.cwd(), 'zig_docs');
    const stdDocsDir = path.join(process.cwd(), 'zig_docs_std');
    const examplesDir = path.join(process.cwd(), 'zig_docs_std', 'Examples');
    const patternsDir = path.join(process.cwd(), 'zig_patterns');

    console.error('Loading documentation into cache...');

    if (fs.existsSync(langDocsDir)) {
      await this.cacheDirectory(langDocsDir, 'zig://doc');
    }

    if (fs.existsSync(stdDocsDir)) {
      await this.cacheDirectory(stdDocsDir, 'zig://std');
    }

    if (fs.existsSync(examplesDir)) {
      await this.cacheExamplesDirectory(examplesDir, 'zig://examples');
    }

    if (fs.existsSync(patternsDir)) {
      await this.cacheDirectory(patternsDir, 'zig://patterns');
    }

    console.error(`Cached ${this.docCache.size} documentation files`);
  }

  // Recursively cache all markdown files in a directory
  async cacheDirectory(dir: string, baseUri: string): Promise<void> {
    const items = await fs.promises.readdir(dir, { withFileTypes: true });

    for (const item of items) {
      const fullPath = path.join(dir, item.name);

      if (item.isDirectory()) {
        // Skip the Examples directory in regular caching
        if (item.name === 'Examples') continue;

        const subUri = `${baseUri}/${item.name}`;
        await this.cacheDirectory(fullPath, subUri);
      } else if (item.isFile() && item.name.endsWith('.md')) {
        try {
          // Read file content
          const content = await fs.promises.readFile(fullPath, 'utf8');

          // Store in cache with relative path as key
          const relativePath = path.relative(process.cwd(), fullPath);
          this.docCache.set(relativePath, content);

          // Build resource list
          const fileName = item.name.replace('.md', '');
          const uri = `${baseUri}/${fileName}`;

          this.resourceList.push({
            uri,
            name: this.formatResourceName(uri),
            description: this.generateDescription(uri),
            mimeType: 'text/markdown',
            _filePath: relativePath
          });
        } catch (error) {
          console.error(`Error caching ${fullPath}:`, error);
        }
      }
    }
  }

  // Cache example files (.zig files) from Examples directory
  async cacheExamplesDirectory(dir: string, baseUri: string): Promise<void> {
    const items = await fs.promises.readdir(dir, { withFileTypes: true });

    for (const item of items) {
      const fullPath = path.join(dir, item.name);

      if (item.isDirectory()) {
        // Recursively cache subdirectories
        const subUri = `${baseUri}/${item.name}`;
        await this.cacheExamplesDirectory(fullPath, subUri);
      } else if (item.isFile() && item.name.endsWith('.zig')) {
        try {
          // Read file content
          const content = await fs.promises.readFile(fullPath, 'utf8');

          // Store in cache with relative path as key
          const relativePath = path.relative(process.cwd(), fullPath);
          this.docCache.set(relativePath, content);

          // Build resource list for examples
          const fileName = item.name.replace('.zig', '');
          // Remove 'test_' prefix for cleaner names
          const cleanName = fileName.replace(/^test_/, '');
          const uri = `${baseUri}/${cleanName}`;

          this.resourceList.push({
            uri,
            name: `Example: ${cleanName}`,
            description: `Working Zig code example for ${cleanName}`,
            mimeType: 'text/x-zig',
            _filePath: relativePath
          });
        } catch (error) {
          console.error(`Error caching example ${fullPath}:`, error);
        }
      }
    }
  }


  formatResourceName(uri: string): string {
    const parts = uri.split('/');
    const last = parts[parts.length - 1];

    // Format different types of names - keep consistent with search results
    if (uri.startsWith('zig://examples/')) {
      return `Example: ${last}`;
    } else if (uri.startsWith('zig://patterns/')) {
      const category = parts[parts.length - 2]; // e.g., memory, errors
      return `Pattern: ${category}/${last.replace(/_/g, ' ')}`;
    } else if (uri.includes('/Types/')) {
      const typeGroup = parts[parts.length - 2]; // e.g., ArrayHashMap
      return `Types.${typeGroup}.${last}`;
    } else if (uri.includes('/Namespaces/')) {
      const namespace = parts[parts.length - 2];
      return `Namespaces.${namespace}.${last}`;
    } else if (uri.startsWith('zig://doc/')) {
      return last.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    } else if (uri === 'zig://std/index') {
      return 'index';
    }

    return last;
  }

  generateDescription(uri: string): string {
    if (uri.startsWith('zig://examples/')) {
      return `Working Zig code example`;
    } else if (uri.startsWith('zig://patterns/')) {
      return `Practical Zig coding pattern with examples`;
    } else if (uri.includes('/Types/')) {
      return `Zig standard library type documentation`;
    } else if (uri.includes('/Namespaces/')) {
      return `Zig standard library namespace documentation`;
    } else if (uri.startsWith('zig://doc/')) {
      return `Zig language documentation`;
    }

    return 'Zig documentation';
  }

  setupResourceHandlers() {
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => {
      // Return cached resource list
      // Filter out internal _filePath property before returning to client
      const resources = this.resourceList.map(({ _filePath, ...rest }) => rest);
      return { resources };
    });

    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const { uri } = request.params;

      try {
        const filePath = this.uriToFilePath(uri);
        const content = await this.readMarkdownFile(filePath);

        return {
          contents: [{
            uri,
            mimeType: 'text/markdown',
            text: content,
          }],
        };
      } catch (error: any) {
        throw new McpError(
          ErrorCode.InvalidRequest,
          `Failed to read resource ${uri}: ${error.message}`
        );
      }
    });
  }

  uriToFilePath(uri: string): string {
    if (uri.startsWith('zig://doc/')) {
      const topic = uri.replace('zig://doc/', '');
      return `zig_docs/${topic.replace(/-/g, '_')}.md`;
    } else if (uri.startsWith('zig://examples/')) {
      const exactMatch = this.resourceList.find(
        resource => resource.uri === uri && resource.uri.startsWith('zig://examples/')
      );
      if (exactMatch) {
        return exactMatch._filePath;
      }

      const exampleName = uri.replace('zig://examples/', '');
      const candidates = [
        `zig_docs_std/Examples/${exampleName}.zig`,
        `zig_docs_std/Examples/test_${exampleName}.zig`,
      ];

      for (const candidate of candidates) {
        if (fs.existsSync(path.join(process.cwd(), candidate))) {
          return candidate;
        }
      }

      return candidates[0];
    } else if (uri.startsWith('zig://patterns/')) {
      const patternPath = uri.replace('zig://patterns/', '');
      return `zig_patterns/${patternPath}.md`;
    } else if (uri.startsWith('zig://std/')) {
      const parts = uri.replace('zig://std/', '').split('/');

      if (parts.length === 1) {
        // Top-level file like index.md
        return `zig_docs_std/${parts[0]}.md`;
      } else {
        // Hierarchical path
        return `zig_docs_std/${parts.join('/')}.md`;
      }
    }

    throw new Error(`Unknown URI format: ${uri}`);
  }

  filePathToUri(filePath: string): string {
    const relativePath = path.relative(process.cwd(), filePath);

    if (relativePath.startsWith('zig_docs/')) {
      const topic = relativePath.replace('zig_docs/', '').replace('.md', '').replace(/_/g, '-');
      return `zig://doc/${topic}`;
    } else if (relativePath.startsWith('zig_patterns/')) {
      const patternPath = relativePath.replace('zig_patterns/', '').replace('.md', '');
      return `zig://patterns/${patternPath}`;
    } else if (relativePath.startsWith('zig_docs_std/')) {
      const stdPath = relativePath.replace('zig_docs_std/', '').replace('.md', '');
      return `zig://std/${stdPath}`;
    }

    throw new Error(`Cannot convert file path to URI: ${relativePath}`);
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'search_zig_docs',
            description: 'Search for specific topics across all Zig documentation',
            inputSchema: {
              type: 'object',
              properties: {
                query: {
                  type: 'string',
                  description: 'Search query for Zig documentation topics',
                },
              },
              required: ['query'],
            },
          },
          {
            name: 'get_builtin_info',
            description: 'Get detailed information about a specific Zig builtin function',
            inputSchema: {
              type: 'object',
              properties: {
                builtin_name: {
                  type: 'string',
                  description: 'Name of the builtin function (with or without @ prefix)',
                },
              },
              required: ['builtin_name'],
            },
          },
          {
            name: 'explain_concept',
            description: 'Get a detailed explanation of a Zig language concept',
            inputSchema: {
              type: 'object',
              properties: {
                concept: {
                  type: 'string',
                  description: 'Zig concept to explain (e.g., "comptime", "defer", "optionals")',
                },
              },
              required: ['concept'],
            },
          },
          {
            name: 'get_syntax_examples',
            description: 'Get syntax examples for Zig language constructs',
            inputSchema: {
              type: 'object',
              properties: {
                construct: {
                  type: 'string',
                  description: 'Language construct to get examples for (e.g., "for loops", "if statements", "struct")',
                },
              },
              required: ['construct'],
            },
          },
          {
            name: 'get_example',
            description: 'Get a working Zig code example by topic or name',
            inputSchema: {
              type: 'object',
              properties: {
                topic: {
                  type: 'string',
                  description: 'Topic or example name (e.g., "arraylist", "reader", "json_parser")',
                },
              },
              required: ['topic'],
            },
          },
          {
            name: 'server_diagnostics',
            description: 'Get server health, cache stats, and diagnostic information',
            inputSchema: {
              type: 'object',
              properties: {
                include_samples: {
                  type: 'boolean',
                  description: 'Include sample resource URIs (default: false)',
                },
              },
            },
          },
          {
            name: 'introspect_type',
            description: 'Introspect a Zig type to see its methods, fields, and structure',
            inputSchema: {
              type: 'object',
              properties: {
                type_expression: {
                  type: 'string',
                  description: 'Zig type expression to introspect (e.g., "std.ArrayList(i32)", "std.heap.GeneralPurposeAllocator({})")',
                },
              },
              required: ['type_expression'],
            },
          },
          {
            name: 'validate_code',
            description: 'Validate a Zig code snippet and get compilation errors if any',
            inputSchema: {
              type: 'object',
              properties: {
                code: {
                  type: 'string',
                  description: 'Zig code snippet to validate',
                },
                code_type: {
                  type: 'string',
                  description: 'Type of code: "test" (default), "main", or "function"',
                  enum: ['test', 'main', 'function'],
                },
              },
              required: ['code'],
            },
          },
          {
            name: 'query_stdlib_source',
            description: 'Query the Zig standard library source code for a specific file/module',
            inputSchema: {
              type: 'object',
              properties: {
                module_path: {
                  type: 'string',
                  description: 'Path to stdlib module (e.g., "std/array_list.zig", "std/heap.zig")',
                },
                search_term: {
                  type: 'string',
                  description: 'Optional: search for specific function or type within the module',
                },
              },
              required: ['module_path'],
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name } = request.params;
      const args = (request.params.arguments ?? {}) as Record<string, unknown>;

      switch (name) {
        case 'search_zig_docs':
          if (typeof args.query !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'search_zig_docs requires string argument "query"');
          }
          return {
            content: [
              {
                type: 'text',
                text: this.searchDocumentation(args.query),
              },
            ],
          };

        case 'get_builtin_info':
          if (typeof args.builtin_name !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'get_builtin_info requires string argument "builtin_name"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.getBuiltinInfo(args.builtin_name),
              },
            ],
          };

        case 'explain_concept':
          if (typeof args.concept !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'explain_concept requires string argument "concept"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.explainConcept(args.concept),
              },
            ],
          };

        case 'get_syntax_examples':
          if (typeof args.construct !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'get_syntax_examples requires string argument "construct"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.getSyntaxExamples(args.construct),
              },
            ],
          };

        case 'get_example':
          if (typeof args.topic !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'get_example requires string argument "topic"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.getExample(args.topic),
              },
            ],
          };

        case 'server_diagnostics':
          return {
            content: [
              {
                type: 'text',
                text: this.getDiagnostics((args.include_samples as boolean | undefined) ?? false),
              },
            ],
          };

        case 'introspect_type':
          if (typeof args.type_expression !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'introspect_type requires string argument "type_expression"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.introspectType(args.type_expression),
              },
            ],
          };

        case 'validate_code':
          if (typeof args.code !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'validate_code requires string argument "code"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.validateCode(
                  args.code,
                  (args.code_type as string | undefined) ?? 'test'
                ),
              },
            ],
          };

        case 'query_stdlib_source':
          if (typeof args.module_path !== 'string') {
            throw new McpError(ErrorCode.InvalidParams, 'query_stdlib_source requires string argument "module_path"');
          }
          return {
            content: [
              {
                type: 'text',
                text: await this.queryStdlibSource(
                  args.module_path,
                  args.search_term as string | undefined
                ),
              },
            ],
          };

        default:
          throw new McpError(
            ErrorCode.InvalidRequest,
            `Unknown tool: ${name}`
          );
      }
    });
  }

  searchDocumentation(query: string): string {
    const results: SearchResult[] = [];

    try {
      // Check if this is a deprecated/migrated API
      const migrationHint = this.checkApiMigration(query);

      // Search in cached documentation
      for (const resource of this.resourceList) {
        const content = this.docCache.get(resource._filePath);
        if (!content) continue;

        const uri = resource.uri;
        const resourceName = resource.name;

        // Extract file name from path
        const fileName = path.basename(resource._filePath, '.md');

        // Determine category
        const category = uri.startsWith('zig://doc/') ? 'Language' : 'Std Library';

        // Calculate match score
        const score = this.calculateMatchScore(query, fileName, resourceName, content);

        if (score > 0) {
          results.push({
            score: score,
            text: `**${category}: ${resourceName}** (score: ${score.toFixed(2)})
  URI: ${uri}`
          });
        }
      }

      // Prepare response
      let response = '';

      // Show migration hint if found
      if (migrationHint) {
        response += `## ⚠️ API Migration Notice\n\n${migrationHint}\n\n---\n\n`;
      }

      if (results.length === 0) {
        const suggestions = this.suggestAlternativeQueries(query);
        return migrationHint ? response + suggestions : suggestions;
      }

      // Sort results by score (highest first)
      results.sort((a, b) => b.score - a.score);

      // Format results
      response += results.slice(0, 10).map(r => r.text).join('\n\n');

      return response;

    } catch (error: any) {
      return `Search error: ${error.message}`;
    }
  }

  // Check if query matches a deprecated/migrated API
  checkApiMigration(query: string): string | null {
    const lowerQuery = query.toLowerCase();

    for (const [oldApi, newInfo] of this.apiMigrationMap.entries()) {
      if (lowerQuery.includes(oldApi.toLowerCase())) {
        return `**"${oldApi}"** → ${newInfo}\n\nYou may be looking for Zig 0.16 changes. Try searching for "migration" or see the migration guides.`;
      }
    }

    return null;
  }

  // Suggest alternative queries when no results found
  suggestAlternativeQueries(originalQuery: string): string {
    const queryWords = this.splitWords(originalQuery);
    const suggestions: Array<{ query: string; count: number }> = [];

    // Try searching with individual words
    for (const word of queryWords) {
      if (word.length < 3) continue; // Skip very short words

      let count = 0;
      for (const resource of this.resourceList) {
        const content = this.docCache.get(resource._filePath);
        if (!content) continue;
        if (content.toLowerCase().includes(word.toLowerCase())) {
          count++;
        }
      }

      if (count > 0) {
        suggestions.push({ query: word, count });
      }
    }

    // Try searching with pairs of words
    if (queryWords.length >= 2) {
      for (let i = 0; i < queryWords.length - 1; i++) {
        const pair = `${queryWords[i]} ${queryWords[i + 1]}`;
        let count = 0;

        for (const resource of this.resourceList) {
          const content = this.docCache.get(resource._filePath);
          if (!content) continue;
          if (content.toLowerCase().includes(pair.toLowerCase())) {
            count++;
          }
        }

        if (count > 0) {
          suggestions.push({ query: pair, count });
        }
      }
    }

    // Try synonyms
    for (const word of queryWords) {
      const synonyms = this.synonymMap.get(word.toLowerCase());
      if (synonyms) {
        for (const synonym of synonyms) {
          let count = 0;
          for (const resource of this.resourceList) {
            const content = this.docCache.get(resource._filePath);
            if (!content) continue;
            if (content.toLowerCase().includes(synonym.toLowerCase())) {
              count++;
            }
          }

          if (count > 0) {
            suggestions.push({ query: synonym, count });
          }
        }
      }
    }

    // Sort by count (most results first) and deduplicate
    const uniqueSuggestions = new Map<string, number>();
    for (const { query, count } of suggestions) {
      if (!uniqueSuggestions.has(query)) {
        uniqueSuggestions.set(query, count);
      }
    }

    const sortedSuggestions = Array.from(uniqueSuggestions.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5);

    if (sortedSuggestions.length > 0) {
      const suggestionText = sortedSuggestions
        .map(([query, count]) => `  - "${query}" (${count} results)`)
        .join('\n');

      return `No documentation found for "${originalQuery}".

Did you mean:
${suggestionText}

Try searching for language features, types, or concepts with simpler terms.`;
    }

    return `No documentation found for "${originalQuery}".

Try searching for:
  - Language features: "comptime", "defer", "error handling"
  - Data types: "array", "slice", "pointer", "struct"
  - Standard library: "allocator", "arraylist", "hashmap"
  - Operations: "overflow", "memory", "io", "formatting"`;
  }


  // Calculate match score based on various criteria
  calculateMatchScore(query: string, fileName: string, resourceName: string, content: string): number {
    let score = 0;
    const lowerQuery = query.toLowerCase();
    const lowerFileName = fileName.toLowerCase();
    const lowerResourceName = resourceName.toLowerCase();
    const lowerContent = content.toLowerCase();

    // Exact match in file name (highest priority)
    if (lowerFileName === lowerQuery) {
      score += 100;
    }

    // Exact match in resource name
    if (lowerResourceName === lowerQuery) {
      score += 90;
    }

    // File name contains query
    if (lowerFileName.includes(lowerQuery)) {
      score += 50;
    }

    // Resource name contains query
    if (lowerResourceName.includes(lowerQuery)) {
      score += 45;
    }

    // Split camelCase/PascalCase and check for matches
    const queryWords = this.splitWords(query);
    const fileWords = this.splitWords(fileName);
    const resourceWords = this.splitWords(resourceName);

    // Check if all query words are in file name
    if (queryWords.every(qw => fileWords.some(fw => fw.toLowerCase().includes(qw.toLowerCase())))) {
      score += 40;
    }

    // Check if all query words are in resource name
    if (queryWords.every(qw => resourceWords.some(rw => rw.toLowerCase().includes(qw.toLowerCase())))) {
      score += 35;
    }

    // Content contains query
    if (lowerContent.includes(lowerQuery)) {
      score += 20;
    }

    // IMPROVED: Partial word matching in content (proportional scoring)
    const matchingWords = queryWords.filter(qw => lowerContent.includes(qw.toLowerCase()));
    if (matchingWords.length > 0) {
      const matchRatio = matchingWords.length / queryWords.length;
      score += matchRatio * 25; // Up to 25 points for partial matches
    }

    // IMPROVED: Synonym-expanded word matching in content
    const expandedWords = this.expandQueryWithSynonyms(queryWords);
    const synonymMatches = expandedWords.filter(ew => lowerContent.includes(ew.toLowerCase()));
    if (synonymMatches.length > 0) {
      const synonymRatio = synonymMatches.length / expandedWords.length;
      score += synonymRatio * 15; // Up to 15 points for synonym matches
    }

    // Fuzzy matching with edit distance
    const editDistance = this.levenshteinDistance(lowerQuery, lowerFileName);
    if (editDistance <= 3) {
      score += (30 - editDistance * 10);
    }

    return score;
  }

  // Expand query words with synonyms
  expandQueryWithSynonyms(queryWords: string[]): string[] {
    const expanded = new Set<string>();

    for (const word of queryWords) {
      expanded.add(word);
      const synonyms = this.synonymMap.get(word.toLowerCase());
      if (synonyms) {
        synonyms.forEach(syn => expanded.add(syn));
      }
    }

    return Array.from(expanded);
  }

  // Split camelCase/PascalCase into words
  splitWords(str: string): string[] {
    return str
      .replace(/([a-z])([A-Z])/g, '$1 $2')
      .replace(/([A-Z])([A-Z][a-z])/g, '$1 $2')
      .split(/[\s\-_]+/)
      .filter(w => w.length > 0);
  }

  // Calculate Levenshtein distance between two strings
  levenshteinDistance(a: string, b: string): number {
    const matrix: number[][] = [];
    
    for (let i = 0; i <= b.length; i++) {
      matrix[i] = [i];
    }
    
    for (let j = 0; j <= a.length; j++) {
      matrix[0][j] = j;
    }
    
    for (let i = 1; i <= b.length; i++) {
      for (let j = 1; j <= a.length; j++) {
        if (b.charAt(i - 1) === a.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1
          );
        }
      }
    }
    
    return matrix[b.length][a.length];
  }

  // Extract all builtin function names from content
  extractAllBuiltins(content: string): string[] {
    const builtins: string[] = [];
    const lines = content.split('\n');

    for (const line of lines) {
      // Match both ## [@functionName] and ### @functionName formats
      if (line.startsWith('## [@') || line.startsWith('### @')) {
        const match = line.match(/\[@?(\w+)\]|### @(\w+)/);
        if (match) {
          const name = match[1] || match[2];
          builtins.push(`@${name}`);
        }
      }
    }

    return builtins;
  }

  // Find similar strings using Levenshtein distance
  findSimilarStrings(target: string, candidates: string[], maxResults = 3): string[] {
    const targetLower = target.toLowerCase();

    const scored = candidates
      .map(candidate => ({
        value: candidate,
        distance: this.levenshteinDistance(targetLower, candidate.toLowerCase()),
      }))
      .filter(item => item.distance <= 3)  // Only suggest if edit distance is 3 or less
      .sort((a, b) => a.distance - b.distance);

    return scored.slice(0, maxResults).map(item => item.value);
  }

  async getBuiltinInfo(builtinName: string): Promise<string> {
    try {
      const normalizedName = builtinName.startsWith('@') ? builtinName : `@${builtinName}`;
      const builtinFilePath = 'zig_docs/builtin_functions.md';
      const content = await this.readMarkdownFile(builtinFilePath);

      const lines = content.split('\n');
      const builtinSection: string[] = [];
      let inSection = false;
      let foundSection = false;

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        // Match exact builtin name from format: "## [@import](#toc-import) §"
        // Extract builtin name from within brackets
        const headingMatch = line.match(/^##\s+\[(@\w+)\]/);
        if (headingMatch && headingMatch[1] === normalizedName) {
          inSection = true;
          foundSection = true;
          builtinSection.push(line);
          continue;
        }

        if (inSection) {
          // Stop when we hit another builtin heading
          if (line.match(/^##\s+\[@\w+\]/)) {
            break;
          }
          builtinSection.push(line);
        }
      }

      if (!foundSection) {
        // Find similar builtins for suggestions
        const allBuiltins = this.extractAllBuiltins(content);
        const similar = this.findSimilarStrings(normalizedName, allBuiltins, 3);

        let message = `Builtin function "${normalizedName}" not found.`;

        if (similar.length > 0) {
          message += `\n\n**Did you mean one of these?**\n${similar.map(b => `  • ${b}`).join('\n')}`;
        }

        message += `\n\n**Troubleshooting:**\n`;
        message += `  • Builtin functions start with @ (e.g., @import, @sizeof)\n`;
        message += `  • Use search_zig_docs to search for related builtins\n`;
        message += `  • Common builtins: @import, @as, @typeInfo, @sizeof, @alignOf`;

        return message;
      }

      const result = builtinSection.join('\n').trim();
      return result || `Information for "${normalizedName}" found but content appears to be empty.`;

    } catch (error: any) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      return `Error retrieving builtin info: ${errorMsg}

**Troubleshooting:**
  • Ensure builtin_functions.md exists in zig_docs/
  • Check file permissions are readable
  • Verify server was built: npm run build
  • Try server_diagnostics tool to check server status`;
    }
  }

  async explainConcept(concept: string): Promise<string> {
    try {
      const conceptMap: Record<string, string> = {
        // Core language features
        'comptime': 'comptime.md',
        'compile time': 'comptime.md',
        'compiletime': 'comptime.md',
        'defer': 'defer.md',
        'errdefer': 'defer.md',
        'optionals': 'optionals.md',
        'optional': 'optionals.md',
        'null': 'optionals.md',
        'errors': 'errors.md',
        'error handling': 'errors.md',
        'error sets': 'errors.md',
        'pointers': 'pointers.md',
        'pointer': 'pointers.md',
        'slices': 'slices.md',
        'slice': 'slices.md',
        'arrays': 'arrays.md',
        'array': 'arrays.md',

        // Data structures
        'struct': 'struct.md',
        'structs': 'struct.md',
        'union': 'union.md',
        'unions': 'union.md',
        'tagged union': 'union.md',
        'enum': 'enum.md',
        'enums': 'enum.md',
        'enumeration': 'enum.md',

        // Control flow
        'for': 'for.md',
        'for loop': 'for.md',
        'for loops': 'for.md',
        'while': 'while.md',
        'while loop': 'while.md',
        'while loops': 'while.md',
        'if': 'if.md',
        'if statement': 'if.md',
        'switch': 'switch.md',
        'switch statement': 'switch.md',
        'blocks': 'blocks.md',
        'block': 'blocks.md',

        // Functions and types
        'functions': 'functions.md',
        'function': 'functions.md',
        'fn': 'functions.md',
        'variables': 'variables.md',
        'var': 'variables.md',
        'const': 'variables.md',
        'values': 'values.md',
        'operators': 'operators.md',
        'operator': 'operators.md',
        'comments': 'comments.md',

        // Memory and performance
        'memory': 'memory.md',
        'allocator': 'memory.md',
        'allocation': 'memory.md',
        'memory management': 'memory.md',
        'casting': 'casting.md',
        'cast': 'casting.md',
        'type conversion': 'casting.md',
        'vectors': 'vectors.md',
        'vector': 'vectors.md',
        'simd': 'vectors.md',
        'atomics': 'atomics.md',
        'atomic': 'atomics.md',

        // Advanced features
        'async': 'async_functions.md',
        'asynchronous': 'async_functions.md',
        'await': 'async_functions.md',
        'assembly': 'assembly.md',
        'inline assembly': 'assembly.md',
        'asm': 'assembly.md',

        // C interop
        'c': 'c.md',
        'c interop': 'c.md',
        'ffi': 'c.md',
        'extern': 'c.md',

        // Build system and testing
        'build': 'zig_build_system.md',
        'build system': 'zig_build_system.md',
        'build.zig': 'zig_build_system.md',
        'test': 'zig_test.md',
        'testing': 'zig_test.md',
        'tests': 'zig_test.md',

        // Additional useful topics
        'integers': 'integers.md',
        'integer': 'integers.md',
        'int': 'integers.md',
        'floats': 'floats.md',
        'float': 'floats.md',
        'builtin': 'builtin_functions.md',
        'builtins': 'builtin_functions.md',
        'builtin functions': 'builtin_functions.md',
        '@': 'builtin_functions.md',

        // Migration guides
        'migration': 'migration_016.md',
        '0.16': 'migration_016.md',
        'zig 0.16': 'migration_016.md',
      };

      const lowercaseConcept = concept.toLowerCase();
      const filename = conceptMap[lowercaseConcept];

      if (!filename) {
        const partialMatch = Object.keys(conceptMap).find(key =>
          key.includes(lowercaseConcept) || lowercaseConcept.includes(key)
        );

        if (partialMatch) {
          const suggestedFilename = conceptMap[partialMatch];
          const filePath = `zig_docs/${suggestedFilename}`;
          const content = await this.readMarkdownFile(filePath);
          return `Found related concept "${partialMatch}":\n\n${content}`;
        }

        const allConcepts = Object.keys(conceptMap);
        const similar = this.findSimilarStrings(lowercaseConcept, allConcepts, 5);

        let message = `Concept "${concept}" not found.`;

        if (similar.length > 0) {
          message += `\n\n**Did you mean one of these?**\n${similar.map(c => `  • ${c}`).join('\n')}`;
        }

        message += `\n\n**Available concepts:** ${allConcepts.join(', ')}`;
        message += `\n\n**Tip:** Use search_zig_docs for broader searches across all documentation.`;

        return message;
      }

      const filePath = `zig_docs/${filename}`;
      const content = await this.readMarkdownFile(filePath);

      return content;

    } catch (error: any) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      return `Error explaining concept: ${errorMsg}

**Troubleshooting:**
  • Ensure documentation files exist in zig_docs/
  • Check file permissions
  • Use search_zig_docs as an alternative
  • Try server_diagnostics to verify server health`;
    }
  }

  async getSyntaxExamples(construct: string): Promise<string> {
    try {
      const constructMap: Record<string, string> = {
        'for': 'for.md',
        'for loops': 'for.md',
        'for loop': 'for.md',
        'while': 'while.md',
        'while loops': 'while.md',
        'while loop': 'while.md',
        'if': 'if.md',
        'if statements': 'if.md',
        'if statement': 'if.md',
        'switch': 'switch.md',
        'switch statements': 'switch.md',
        'switch statement': 'switch.md',
        'struct': 'struct.md',
        'structs': 'struct.md',
        'union': 'union.md',
        'unions': 'union.md',
        'enum': 'enum.md',
        'enums': 'enum.md',
        'functions': 'functions.md',
        'function': 'functions.md',
        'fn': 'functions.md',
        'arrays': 'arrays.md',
        'array': 'arrays.md',
        'slices': 'slices.md',
        'slice': 'slices.md',
        'pointers': 'pointers.md',
        'pointer': 'pointers.md',
        'optionals': 'optionals.md',
        'optional': 'optionals.md',
        'null': 'optionals.md',
        'errors': 'errors.md',
        'error': 'errors.md',
        'error handling': 'errors.md',
        'try': 'errors.md',
        'catch': 'errors.md',
        'defer': 'defer.md',
        'errdefer': 'defer.md',
        'comptime': 'comptime.md',
        'compile time': 'comptime.md',
        'blocks': 'blocks.md',
        'block': 'blocks.md',
        'memory': 'memory.md',
        'allocator': 'memory.md',
        'allocation': 'memory.md',
        'casting': 'casting.md',
        'cast': 'casting.md',
        'type conversion': 'casting.md',
        'vectors': 'vectors.md',
        'vector': 'vectors.md',
        'simd': 'vectors.md',
        'atomics': 'atomics.md',
        'atomic': 'atomics.md',
        'threading': 'atomics.md',
        'variables': 'variables.md',
        'var': 'variables.md',
        'const': 'variables.md',
        'values': 'values.md',
        'operators': 'operators.md',
        'operator': 'operators.md',
      };

      const lowercaseConstruct = construct.toLowerCase();
      const filename = constructMap[lowercaseConstruct];

      if (!filename) {
        // Try partial matching with better fuzzy matching
        const partialMatch = Object.keys(constructMap).find(key =>
          key.includes(lowercaseConstruct) || lowercaseConstruct.includes(key)
        );

        if (partialMatch) {
          const suggestedFilename = constructMap[partialMatch];
          const filePath = `zig_docs/${suggestedFilename}`;

          try {
            const content = await this.readMarkdownFile(filePath);
            const examples = this.extractCodeExamples(content);
            return `Found syntax examples for "${partialMatch}":\n\n${examples}`;
          } catch (readError: any) {
            console.error(`Failed to read ${filePath}:`, readError);
            return `Found match "${partialMatch}" but failed to read documentation: ${readError.message}`;
          }
        }

        // Use fuzzy matching to suggest similar constructs
        const availableConstructs = [...new Set(Object.keys(constructMap))];
        const similar = this.findSimilarStrings(lowercaseConstruct, availableConstructs, 5);

        let message = `Construct "${construct}" not found.`;

        if (similar.length > 0) {
          message += `\n\n**Did you mean one of these?**\n${similar.map(c => `  • ${c}`).join('\n')}`;
        }

        message += `\n\n**Tip:** Use search_zig_docs for broader searches across all documentation.`;

        return message;
      }

      const filePath = `zig_docs/${filename}`;

      try {
        const content = await this.readMarkdownFile(filePath);
        const examples = this.extractCodeExamples(content);
        return examples;
      } catch (readError: any) {
        // More detailed error handling
        console.error(`Error reading ${filePath}:`, readError);
        return `Error getting syntax examples: ${readError.message}

**Troubleshooting:**
  • File path: ${filePath}
  • Ensure documentation files exist in zig_docs/
  • Try server_diagnostics to check server health
  • Use search_zig_docs as an alternative`;
      }

    } catch (error: any) {
      return `Error getting syntax examples: ${error.message}\n\nUse search_zig_docs or explain_concept as alternatives.`;
    }
  }

  extractCodeExamples(content: string): string {
    const lines = content.split('\n');
    const examples: string[] = [];
    let inCodeBlock = false;
    let currentExample: string[] = [];
    let exampleCount = 0;

    for (const line of lines) {
      if (line.trim().startsWith('```zig') || line.trim().startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          currentExample = [];
          if (line.trim() === '```zig') {
            currentExample.push(line);
          }
        } else {
          inCodeBlock = false;
          currentExample.push(line);
          examples.push(currentExample.join('\n'));
          exampleCount++;
          if (exampleCount >= 5) break;
        }
      } else if (inCodeBlock) {
        currentExample.push(line);
      }
    }

    if (examples.length === 0) {
      return 'No code examples found in the documentation for this construct.';
    }

    return examples.join('\n\n---\n\n');
  }

  async getExample(topic: string): Promise<string> {
    try {
      const lowerTopic = topic.toLowerCase();

      // Search for matching examples in cache
      const matches: { score: number; name: string; uri: string; filePath: string; content: string }[] = [];

      for (const resource of this.resourceList) {
        if (!resource.uri.startsWith('zig://examples/')) continue;

        const exampleName = resource.uri.replace('zig://examples/', '').toLowerCase();
        const content = this.docCache.get(resource._filePath);

        if (!content) continue;

        // Calculate match score
        let score = 0;

        // Exact match
        if (exampleName === lowerTopic) {
          score = 100;
        }
        // Example name contains topic
        else if (exampleName.includes(lowerTopic)) {
          score = 80;
        }
        // Topic contains example name (partial match)
        else if (lowerTopic.includes(exampleName)) {
          score = 60;
        }
        // Check content for topic keywords
        else if (content.toLowerCase().includes(lowerTopic)) {
          score = 40;
        }

        if (score > 0) {
          matches.push({
            score,
            name: exampleName,
            uri: resource.uri,
            filePath: resource._filePath,
            content
          });
        }
      }

      if (matches.length === 0) {
        // List available examples
        const availableExamples = this.resourceList
          .filter(r => r.uri.startsWith('zig://examples/'))
          .map(r => r.uri.replace('zig://examples/', ''))
          .sort()
          .slice(0, 20);

        return `No examples found for "${topic}". Available examples include:\n\n${availableExamples.join(', ')}`;
      }

      // Sort by score and get best match
      matches.sort((a, b) => b.score - a.score);
      const bestMatch = matches[0];

      // Format the response
      let response = `# Example: ${bestMatch.name}\n\n`;
      response += `Found working example code:\n\n`;
      response += `\`\`\`zig\n${bestMatch.content}\n\`\`\`\n`;

      // If there are other matches, mention them
      if (matches.length > 1) {
        const otherMatches = matches.slice(1, 4).map(m => m.name);
        response += `\n\nRelated examples: ${otherMatches.join(', ')}`;
      }

      return response;

    } catch (error: any) {
      return `Error retrieving example: ${error.message}`;
    }
  }

  getDiagnostics(includeSamples: boolean): string {
    const langDocs = this.resourceList.filter(r => r.uri.startsWith('zig://doc/')).length;
    const stdDocs = this.resourceList.filter(r => r.uri.startsWith('zig://std/')).length;
    const examples = this.resourceList.filter(r => r.uri.startsWith('zig://examples/')).length;

    const memUsage = process.memoryUsage();
    const uptime = process.uptime();

    let output = `# Server Diagnostics

**Server Name:** ${this.serverName}
**Server Version:** ${this.serverVersion}
**Node Version:** ${process.version}
**Platform:** ${process.platform} ${process.arch}

## Cache Status
- **Total Cached Files:** ${this.docCache.size}
- **Total Resources:** ${this.resourceList.length}
- **Cache Size (MB):** ${(memUsage.heapUsed / 1024 / 1024).toFixed(2)}

## Documentation Breakdown
- **Language Docs:** ${langDocs} files
- **Standard Library Docs:** ${stdDocs} files
- **Working Examples:** ${examples} files

## Memory Usage
- **RSS:** ${(memUsage.rss / 1024 / 1024).toFixed(2)} MB
- **Heap Used:** ${(memUsage.heapUsed / 1024 / 1024).toFixed(2)} MB
- **Heap Total:** ${(memUsage.heapTotal / 1024 / 1024).toFixed(2)} MB
- **External:** ${(memUsage.external / 1024 / 1024).toFixed(2)} MB

## Runtime
- **Uptime:** ${uptime.toFixed(2)} seconds
- **PID:** ${process.pid}
`;

    if (includeSamples) {
      const sampleLangDocs = this.resourceList
        .filter(r => r.uri.startsWith('zig://doc/'))
        .slice(0, 5)
        .map(r => `  • ${r.uri} - ${r.name}`)
        .join('\n');

      const sampleStdDocs = this.resourceList
        .filter(r => r.uri.startsWith('zig://std/'))
        .slice(0, 5)
        .map(r => `  • ${r.uri} - ${r.name}`)
        .join('\n');

      const sampleExamples = this.resourceList
        .filter(r => r.uri.startsWith('zig://examples/'))
        .slice(0, 5)
        .map(r => `  • ${r.uri} - ${r.name}`)
        .join('\n');

      output += `
## Sample Resources

**Language Documentation (first 5):**
${sampleLangDocs}

**Standard Library (first 5):**
${sampleStdDocs}

**Examples (first 5):**
${sampleExamples}
`;
    }

    return output.trim();
  }

  async introspectType(typeExpression: string): Promise<string> {
    try {
      // Use @compileLog to dump type information at compile time
      const testCode = `
const std = @import("std");

test "introspect" {
    const T = ${typeExpression};
    @compileLog("Type:", @typeName(T));
    @compileLog("TypeInfo:", @typeInfo(T));
}
`;

      const tmpFile = `/tmp/zig_introspect_${Date.now()}.zig`;
      fs.writeFileSync(tmpFile, testCode);

      try {
        // Run zig test - @compileLog outputs go to stderr
        execSync(`zig test ${tmpFile} 2>&1`, {
          encoding: 'utf8',
          timeout: 5000,
        });

        // If we get here, compilation succeeded (shouldn't happen with @compileLog)
        fs.unlinkSync(tmpFile);
        return `# Type Introspection: ${typeExpression}

Unexpected success - @compileLog should have triggered a compilation message.`;

      } catch (error: any) {
        // Clean up temp file
        if (fs.existsSync(tmpFile)) {
          fs.unlinkSync(tmpFile);
        }

        // @compileLog causes compilation to stop and output goes to stderr
        const output = error.stdout || error.stderr || error.message;

        // Parse the @compileLog output
        if (output.includes('Compile Log Output:')) {
          // Extract just the compile log section
          const logMatch = output.match(/Compile Log Output:\s*([\s\S]*?)(?:\n\n|$)/);
          const rawLog = logMatch ? logMatch[1] : output;

          // Try to extract the type name and basic info
          const typeNameMatch = rawLog.match(/\[28:\d+\]u8, "([^"]+)"/);
          const typeName = typeNameMatch ? typeNameMatch[1] : typeExpression;

          // Try to extract struct info
          const structMatch = rawLog.match(/\.struct = \.{ \.layout = \.(\w+).*?\.fields = &\.\{.*?\}\[0\.\.(\d+)\].*?\.decls = &\.\{.*?\}\[0\.\.(\d+)\]/);

          let result = `# Type Introspection: ${typeExpression}\n\n`;
          result += `**Actual Type:** \`${typeName}\`\n\n`;

          if (structMatch) {
            result += `**Category:** Struct\n`;
            result += `**Layout:** ${structMatch[1]}\n`;
            result += `**Fields:** ${structMatch[2]}\n`;
            result += `**Declarations:** ${structMatch[3]} (methods/constants/types)\n\n`;
          }

          result += `**Raw Compile Log:**\n\`\`\`\n${rawLog.trim()}\n\`\`\`\n\n`;
          result += `**💡 Tip:** Use \`query_stdlib_source("array_list.zig", "Aligned")\` to see the actual source code and method signatures.`;

          return result;
        }

        return `# Type Introspection Failed

**Expression:** \`${typeExpression}\`

**Error:**
\`\`\`
${output}
\`\`\`

This type expression may be invalid or requires additional context.`;
      }
    } catch (error: any) {
      return `Error introspecting type: ${error.message}`;
    }
  }

  async validateCode(code: string, codeType: string = 'test'): Promise<string> {
    try {
      // Check if code already imports std to avoid duplicate imports
      const hasStdImport = /const\s+std\s*=\s*@import\s*\(\s*"std"\s*\)/.test(code);
      const stdImport = hasStdImport ? '' : 'const std = @import("std");\n\n';

      let fullCode: string;

      switch (codeType) {
        case 'main':
          fullCode = `${stdImport}${code}`;
          break;
        case 'function':
          fullCode = `${stdImport}${code}\n\ntest "validate" { _ = &main; }`;
          break;
        case 'test':
        default:
          fullCode = `${stdImport}${code}`;
          break;
      }

      const tmpFile = `/tmp/zig_validate_${Date.now()}.zig`;
      fs.writeFileSync(tmpFile, fullCode);

      try {
        const output = execSync(`zig test ${tmpFile} 2>&1`, {
          encoding: 'utf8',
          timeout: 10000,
        });

        fs.unlinkSync(tmpFile);

        return `# ✅ Code Validation Passed

**Code Type:** ${codeType}

**Output:**
\`\`\`
${output.trim()}
\`\`\`

The code compiles successfully!`;
      } catch (error: any) {
        if (fs.existsSync(tmpFile)) {
          fs.unlinkSync(tmpFile);
        }

        const errorOutput = error.stdout || error.stderr || error.message;

        return `# ❌ Code Validation Failed

**Code Type:** ${codeType}

**Compilation Errors:**
\`\`\`
${errorOutput}
\`\`\`

Fix the errors above to make the code compile.`;
      }
    } catch (error: any) {
      return `Error validating code: ${error.message}`;
    }
  }

  async queryStdlibSource(modulePath: string, searchTerm?: string): Promise<string> {
    try {
      // Find Zig stdlib installation
      // Note: zig env outputs Zig syntax (.{...}), not JSON
      const zigEnvOutput = execSync('zig env', { encoding: 'utf8' });

      // Extract std_dir using regex (it's in Zig struct format, not JSON)
      const stdDirMatch = zigEnvOutput.match(/\.std_dir\s*=\s*"([^"]+)"/);
      if (!stdDirMatch) {
        throw new Error('Failed to find std_dir in zig env output');
      }

      const stdlibPath = stdDirMatch[1];

      // Normalize module path - remove leading "std/" if present since stdlibPath already points to std/
      let normalizedPath = modulePath.replace(/^std\//, '');

      let fullPath = path.join(stdlibPath, normalizedPath);
      if (!fullPath.endsWith('.zig')) {
        fullPath += '.zig';
      }

      if (!fs.existsSync(fullPath)) {
        return `# ❌ Module Not Found

**Path:** \`${modulePath}\`
**Resolved:** \`${fullPath}\`

The module does not exist in the standard library.

**Available stdlib root:**
\`\`\`
${fs.readdirSync(stdlibPath).filter(f => f.endsWith('.zig')).slice(0, 20).join('\\n')}
...
\`\`\``;
      }

      const content = fs.readFileSync(fullPath, 'utf8');
      const lines = content.split('\n');

      if (searchTerm) {
        // Search for the term in the file
        const matches: string[] = [];
        lines.forEach((line, idx) => {
          if (line.toLowerCase().includes(searchTerm.toLowerCase())) {
            // Include surrounding context
            const start = Math.max(0, idx - 2);
            const end = Math.min(lines.length, idx + 3);
            const context = lines.slice(start, end).map((l, i) => {
              const lineNum = start + i + 1;
              const marker = (start + i === idx) ? '>' : ' ';
              return `${marker} ${lineNum}: ${l}`;
            }).join('\n');
            matches.push(context);
          }
        });

        if (matches.length === 0) {
          return `# 🔍 No Matches Found

**Module:** \`${modulePath}\`
**Search Term:** \`${searchTerm}\`

The search term was not found in this module.`;
        }

        return `# 🔍 Search Results in ${modulePath}

**Search Term:** \`${searchTerm}\`
**Matches Found:** ${matches.length}

\`\`\`zig
${matches.slice(0, 10).join('\n\n---\n\n')}
\`\`\`

${matches.length > 10 ? `\n*(Showing first 10 of ${matches.length} matches)*` : ''}`;
      } else {
        // Return first 100 lines or summary
        const summary = lines.slice(0, 100).join('\n');
        return `# 📄 ${modulePath}

**Full Path:** \`${fullPath}\`
**Lines:** ${lines.length}

## Preview (first 100 lines):

\`\`\`zig
${summary}
\`\`\`

${lines.length > 100 ? `\n*(File has ${lines.length} total lines)*` : ''}

**Tip:** Use the \`search_term\` parameter to find specific functions or types.`;
      }
    } catch (error: any) {
      return `Error querying stdlib source: ${error.message}`;
    }
  }

  async run() {
    // Load all documentation into cache before starting
    await this.loadDocsIntoCache();

    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Zig Documentation MCP server running on stdio');
  }
}

const isMainModule = process.argv[1]
  && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMainModule) {
  const server = new ZigDocumentationServer();
  server.run().catch(console.error);
}

export { ZigDocumentationServer };
