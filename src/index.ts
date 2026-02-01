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
      const exampleName = uri.replace('zig://examples/', '');
      // Try to find the file (check both with and without test_ prefix)
      return `zig_docs_std/Examples/test_${exampleName}.zig`;
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
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;
      
      if (!args) {
          throw new McpError(ErrorCode.InvalidParams, "No arguments provided");
      }

      switch (name) {
        case 'search_zig_docs':
          return {
            content: [
              {
                type: 'text',
                text: this.searchDocumentation(args.query as string),
              },
            ],
          };

        case 'get_builtin_info':
          return {
            content: [
              {
                type: 'text',
                text: await this.getBuiltinInfo(args.builtin_name as string),
              },
            ],
          };

        case 'explain_concept':
          return {
            content: [
              {
                type: 'text',
                text: await this.explainConcept(args.concept as string),
              },
            ],
          };

        case 'get_syntax_examples':
          return {
            content: [
              {
                type: 'text',
                text: await this.getSyntaxExamples(args.construct as string),
              },
            ],
          };

        case 'get_example':
          return {
            content: [
              {
                type: 'text',
                text: await this.getExample(args.topic as string),
              },
            ],
          };

        case 'server_diagnostics':
          return {
            content: [
              {
                type: 'text',
                text: this.getDiagnostics(args.include_samples as boolean ?? false),
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

      if (results.length === 0) {
        return `No documentation found for "${query}". Try searching for language features, types, or concepts.`;
      }

      // Sort results by score (highest first)
      results.sort((a, b) => b.score - a.score);

      // Format results
      return results.slice(0, 10).map(r => r.text).join('\n\n');

    } catch (error: any) {
      return `Search error: ${error.message}`;
    }
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
    
    // Check for word matches in content
    if (queryWords.every(qw => lowerContent.includes(qw.toLowerCase()))) {
      score += 15;
    }
    
    // Fuzzy matching with edit distance
    const editDistance = this.levenshteinDistance(lowerQuery, lowerFileName);
    if (editDistance <= 3) {
      score += (30 - editDistance * 10);
    }
    
    return score;
  }

  // Split camelCase/PascalCase into words
  splitWords(str: string): string[] {
    return str
      .replace(/([a-z])([A-Z])/g, '$1 $2')
      .replace(/([A-Z])([A-Z][a-z])/g, '$1 $2')
      .split(/[ -- -⁯⸀-⹿\s\-_]+/)
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

        if (line.startsWith('### @') && line.includes(normalizedName.substring(1))) {
          inSection = true;
          foundSection = true;
          builtinSection.push(line);
          continue;
        }

        if (inSection) {
          if (line.startsWith('### @') && !line.includes(normalizedName.substring(1))) {
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
        'comptime': 'comptime.md',
        'defer': 'defer.md',
        'optionals': 'optionals.md',
        'errors': 'errors.md',
        'pointers': 'pointers.md',
        'slices': 'slices.md',
        'arrays': 'arrays.md',
        'struct': 'struct.md',
        'union': 'union.md',
        'enum': 'enum.md',
        'for': 'for.md',
        'while': 'while.md',
        'if': 'if.md',
        'switch': 'switch.md',
        'blocks': 'blocks.md',
        'functions': 'functions.md',
        'memory': 'memory.md',
        'casting': 'casting.md',
        'vectors': 'vectors.md',
        'atomics': 'atomics.md',
        'async': 'async_functions.md',
        'assembly': 'assembly.md',
        'c': 'c.md',
        'build': 'zig_build_system.md',
        'test': 'zig_test.md',
        'variables': 'variables.md',
        'values': 'values.md',
        'operators': 'operators.md',
        'comments': 'comments.md'
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
        'arrays': 'arrays.md',
        'array': 'arrays.md',
        'slices': 'slices.md',
        'slice': 'slices.md',
        'pointers': 'pointers.md',
        'pointer': 'pointers.md',
        'optionals': 'optionals.md',
        'optional': 'optionals.md',
        'errors': 'errors.md',
        'error': 'errors.md',
        'defer': 'defer.md',
        'comptime': 'comptime.md',
        'blocks': 'blocks.md',
        'block': 'blocks.md'
      };

      const lowercaseConstruct = construct.toLowerCase();
      const filename = constructMap[lowercaseConstruct];

      if (!filename) {
        const partialMatch = Object.keys(constructMap).find(key =>
          key.includes(lowercaseConstruct) || lowercaseConstruct.includes(key)
        );

        if (partialMatch) {
          const suggestedFilename = constructMap[partialMatch];
          const filePath = `zig_docs/${suggestedFilename}`;
          const content = await this.readMarkdownFile(filePath);

          const examples = this.extractCodeExamples(content);
          return `Found syntax examples for "${partialMatch}":\n\n${examples}`;
        }

        const availableConstructs = [...new Set(Object.keys(constructMap))].join(', ');
        return `Construct "${construct}" not found. Available constructs: ${availableConstructs}`;
      }

      const filePath = `zig_docs/${filename}`;
      const content = await this.readMarkdownFile(filePath);

      const examples = this.extractCodeExamples(content);
      return examples;

    } catch (error: any) {
      return `Error getting syntax examples: ${error.message}`;
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

  async run() {
    // Load all documentation into cache before starting
    await this.loadDocsIntoCache();

    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Zig Documentation MCP server running on stdio');
  }
}

const server = new ZigDocumentationServer();
server.run().catch(console.error);

export { ZigDocumentationServer };
