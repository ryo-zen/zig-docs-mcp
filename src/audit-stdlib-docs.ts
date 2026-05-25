#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..');
const CONTRACT_FILE = 'zig-version-contract.json';

interface ZigVersionContract {
  targetZigVersion: string;
  stdlibSource: {
    expectedPath: string;
    overrideEnvVar: string;
    policy: string;
  };
  upgradePolicy: string;
}

interface CliOptions {
  paths: string[];
  json: boolean;
  includeOk: boolean;
  failOnIssues: boolean;
  maxFindings: number;
}

interface SourceScope {
  filePath: string;
  content: string;
  lineOffset: number;
  description: string;
  ownerDeclaration?: Declaration;
}

type DeclarationKind =
  | 'fn'
  | 'struct'
  | 'union'
  | 'enum'
  | 'error-set'
  | 'import'
  | 'const'
  | 'alias'
  | 'field'
  | 'enum-value'
  | 'error-member'
  | 'unknown';

interface Declaration {
  name: string;
  kind: DeclarationKind;
  filePath: string;
  line: number;
  snippet: string;
  expression: string | null;
  importPath?: string;
  importMember?: string;
  enumValues: string[];
  structFields: string[];
  errorMembers: string[];
  signature?: string;
}

interface ResolveResult {
  ok: boolean;
  symbol: string;
  declaration?: Declaration;
  message?: string;
  trace: string[];
}

type AuditSeverity = 'ok' | 'warning' | 'error' | 'skipped';

interface AuditFinding {
  severity: AuditSeverity;
  code: string;
  file: string;
  symbol: string | null;
  message: string;
  source?: {
    file: string;
    line: number;
    kind: DeclarationKind;
  };
  details?: string[];
}

interface AuditSummary {
  checked: number;
  ok: number;
  warnings: number;
  errors: number;
  skipped: number;
}

interface CoverageRule {
  namespace: string;
  docRoot: string;
  expectedDir: string;
  symbols: string[];
}

type RootDeclarationCategory = 'Types' | 'Namespaces' | 'Values';

interface RootCoverageRule {
  namespace: 'std';
  sourceFile: string;
  categories: Array<{
    category: RootDeclarationCategory;
    docRoot: string;
    expectedDir: string;
  }>;
}

const COVERAGE_RULES: CoverageRule[] = [
  {
    namespace: 'std.Io',
    docRoot: 'zig_docs_std/Types/Io',
    expectedDir: 'zig_docs_std/Types/Io/Types',
    symbols: [
      'AnyFuture',
      'Batch',
      'CancelProtection',
      'Clock',
      'Condition',
      'Dir',
      'Dispatch',
      'Duration',
      'Event',
      'Evented',
      'File',
      'Future',
      'Group',
      'Kqueue',
      'Limit',
      'LockedStderr',
      'Mutex',
      'Operation',
      'Queue',
      'Reader',
      'RwLock',
      'Select',
      'Semaphore',
      'Terminal',
      'Threaded',
      'Timeout',
      'Timestamp',
      'TypeErasedQueue',
      'Uring',
      'VTable',
      'Writer',
      'failingNetSend',
    ],
  },
];

const ROOT_COVERAGE_RULES: RootCoverageRule[] = [
  {
    namespace: 'std',
    sourceFile: 'std.zig',
    categories: [
      {
        category: 'Types',
        docRoot: 'zig_docs_std/Types',
        expectedDir: 'zig_docs_std/Types',
      },
      {
        category: 'Namespaces',
        docRoot: 'zig_docs_std/Namespaces',
        expectedDir: 'zig_docs_std/Namespaces',
      },
      {
        category: 'Values',
        docRoot: 'zig_docs_std/Namespaces',
        expectedDir: 'zig_docs_std/Namespaces',
      },
    ],
  },
];

function printHelp(): void {
  console.log(`Usage: npm run audit:stdlib-docs -- [options] [path ...]

Audits MCP std markdown docs against the locked local Zig stdlib source.

Options:
  --path <path>        Markdown file or directory to audit. Can be repeated.
  --json              Print JSON output.
  --include-ok        Include OK findings in text output.
  --fail-on-issues    Exit non-zero when warnings or errors are found.
  --max <n>           Maximum text findings to print. Default: 200.
  -h, --help          Show this help.

Examples:
  npm run audit:stdlib-docs -- --path zig_docs_std/Namespaces/process/std.process.ArgExpansion.md
  npm run audit:stdlib-docs -- --path zig_docs_std/Namespaces/process --include-ok
`);
}

function parseArgs(argv: string[]): CliOptions {
  const options: CliOptions = {
    paths: [],
    json: false,
    includeOk: false,
    failOnIssues: false,
    maxFindings: 200,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];

    switch (arg) {
      case '--path': {
        const value = argv[i + 1];
        if (!value) throw new Error('--path requires a value');
        options.paths.push(value);
        i += 1;
        break;
      }
      case '--json':
        options.json = true;
        break;
      case '--include-ok':
        options.includeOk = true;
        break;
      case '--fail-on-issues':
        options.failOnIssues = true;
        break;
      case '--max': {
        const value = Number(argv[i + 1]);
        if (!Number.isInteger(value) || value < 1) {
          throw new Error('--max requires a positive integer');
        }
        options.maxFindings = value;
        i += 1;
        break;
      }
      case '-h':
      case '--help':
        printHelp();
        process.exit(0);
        break;
      default:
        if (arg.startsWith('-')) {
          throw new Error(`Unknown option: ${arg}`);
        }
        options.paths.push(arg);
        break;
    }
  }

  if (options.paths.length === 0) {
    options.paths = [
      'zig_docs_std/Namespaces',
      'zig_docs_std/Types',
    ];
  }

  return options;
}

function loadContract(): ZigVersionContract {
  const contractPath = path.join(REPO_ROOT, CONTRACT_FILE);
  const raw = fs.readFileSync(contractPath, 'utf8');
  const contract = JSON.parse(raw) as ZigVersionContract;

  if (
    typeof contract.targetZigVersion !== 'string' ||
    typeof contract.stdlibSource?.expectedPath !== 'string' ||
    typeof contract.stdlibSource?.overrideEnvVar !== 'string' ||
    typeof contract.stdlibSource?.policy !== 'string' ||
    typeof contract.upgradePolicy !== 'string'
  ) {
    throw new Error(`${CONTRACT_FILE} is missing required fields`);
  }

  return contract;
}

function resolveRepoPath(inputPath: string): string {
  return path.isAbsolute(inputPath)
    ? inputPath
    : path.resolve(REPO_ROOT, inputPath);
}

function walkMarkdownFiles(inputPaths: string[]): string[] {
  const files: string[] = [];

  for (const inputPath of inputPaths) {
    const absolutePath = resolveRepoPath(inputPath);
    if (!fs.existsSync(absolutePath)) {
      throw new Error(`Path does not exist: ${inputPath}`);
    }

    const stat = fs.statSync(absolutePath);
    if (stat.isFile()) {
      if (absolutePath.endsWith('.md')) {
        files.push(absolutePath);
      }
      continue;
    }

    if (!stat.isDirectory()) continue;

    const entries = fs.readdirSync(absolutePath, { withFileTypes: true });
    for (const entry of entries) {
      const childPath = path.join(absolutePath, entry.name);
      if (entry.isDirectory()) {
        files.push(...walkMarkdownFiles([childPath]));
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        files.push(childPath);
      }
    }
  }

  return Array.from(new Set(files)).sort();
}

function relativeToRepo(filePath: string): string {
  return path.relative(REPO_ROOT, filePath);
}

function pathContains(parentPath: string, childPath: string): boolean {
  const relativePath = path.relative(parentPath, childPath);
  return relativePath === '' || (!relativePath.startsWith('..') && !path.isAbsolute(relativePath));
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function inferSymbol(filePath: string, content: string): string | null {
  const headingMatch = content.match(/^#\s+`?(std(?:\.[A-Za-z_][A-Za-z0-9_]*)+)`?\s*$/m);
  if (headingMatch) return headingMatch[1];

  const basename = path.basename(filePath, '.md');
  return /^std(?:\.[A-Za-z_][A-Za-z0-9_]*)+$/.test(basename) ? basename : null;
}

function removeLineComment(line: string): string {
  const index = line.indexOf('//');
  return index >= 0 ? line.slice(0, index) : line;
}

function braceDelta(line: string): number {
  const cleaned = removeLineComment(line);
  let delta = 0;

  for (const char of cleaned) {
    if (char === '{') delta += 1;
    if (char === '}') delta -= 1;
  }

  return delta;
}

function parenDelta(line: string): number {
  const cleaned = removeLineComment(line);
  let delta = 0;

  for (const char of cleaned) {
    if (char === '(') delta += 1;
    if (char === ')') delta -= 1;
  }

  return delta;
}

function collectDeclaration(lines: string[], startIndex: number): string {
  const firstLine = lines[startIndex];
  const isFunction = /^\s*pub\s+(?:inline\s+|noinline\s+|export\s+|extern\s+)*fn\b/.test(firstLine);
  const collected: string[] = [];
  let braceDepth = 0;
  let parenDepth = 0;
  let sawBrace = false;

  for (let i = startIndex; i < lines.length; i += 1) {
    const line = lines[i];
    collected.push(line);
    parenDepth += parenDelta(line);

    if (isFunction) {
      const delta = braceDelta(line);
      if (delta !== 0) sawBrace = true;
      braceDepth += delta;

      if (sawBrace && braceDepth <= 0) break;
      if (!sawBrace && line.includes(';') && parenDepth <= 0) break;
      continue;
    }

    const delta = braceDelta(line);
    if (delta !== 0) sawBrace = true;
    braceDepth += delta;

    if (sawBrace) {
      if (braceDepth <= 0 && line.includes(';')) break;
    } else if (line.includes(';')) {
      break;
    }
  }

  return collected.join('\n');
}

function extractBalancedBody(snippet: string): string | null {
  const start = snippet.indexOf('{');
  if (start < 0) return null;

  let depth = 0;
  for (let i = start; i < snippet.length; i += 1) {
    const char = snippet[i];
    if (char === '{') depth += 1;
    if (char === '}') {
      depth -= 1;
      if (depth === 0) {
        return snippet.slice(start + 1, i);
      }
    }
  }

  return null;
}

function splitDeclItems(body: string): string[] {
  return body
    .split(',')
    .map(item => item.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '').trim())
    .map(item => item.replace(/=.*/s, '').trim())
    .filter(item => /^[A-Za-z_][A-Za-z0-9_]*$/.test(item));
}

function extractEnumValues(snippet: string): string[] {
  const body = extractBalancedBody(snippet);
  if (!body) return [];

  const values = new Set(splitDeclItems(body));
  for (const line of body.split('\n')) {
    const cleaned = removeLineComment(line);
    const match = cleaned.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:=[^,]+)?\s*,/);
    if (match) values.add(match[1]);
  }

  return Array.from(values).sort();
}

function extractErrorMembers(snippet: string): string[] {
  const body = extractBalancedBody(snippet);
  return body ? splitDeclItems(body) : [];
}

function extractStructFields(snippet: string): string[] {
  const body = extractBalancedBody(snippet);
  if (!body) return [];

  const fields = new Set<string>();
  for (const line of body.split('\n')) {
    const cleaned = removeLineComment(line);
    const match = cleaned.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:/);
    if (match) fields.add(match[1]);
  }

  return Array.from(fields).sort();
}

function extractUnionFields(snippet: string): string[] {
  const body = extractBalancedBody(snippet);
  if (!body) return [];

  const fields = new Set<string>();
  for (const line of body.split('\n')) {
    const cleaned = removeLineComment(line);
    const match = cleaned.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?::|,)/);
    if (match) fields.add(match[1]);
  }

  return Array.from(fields).sort();
}

function normalizeSignature(snippet: string): string {
  const header = snippet.split('{')[0].replace(/;\s*$/, '');
  return header.replace(/\s+/g, ' ').trim();
}

function analyzeDeclaration(name: string, snippet: string, filePath: string, line: number): Declaration {
  const firstLine = snippet.split('\n')[0];
  const fnMatch = firstLine.match(/^\s*pub\s+(?:inline\s+|noinline\s+|export\s+|extern\s+)*fn\s+/);

  if (fnMatch) {
    return {
      name,
      kind: 'fn',
      filePath,
      line,
      snippet,
      expression: null,
      enumValues: [],
      structFields: [],
      errorMembers: [],
      signature: normalizeSignature(snippet),
    };
  }

  const expressionMatch = snippet.match(/=\s*([\s\S]*?);?\s*$/);
  const expression = expressionMatch ? expressionMatch[1].trim().replace(/;\s*$/, '') : null;
  const importMatch = expression?.match(/^@import\("([^"]+)"\)(?:\.([A-Za-z_][A-Za-z0-9_]*))?$/);

  let kind: DeclarationKind = 'const';
  if (importMatch) {
    kind = 'import';
  } else if (/\b(?:packed\s+)?struct\s*(?:\([^)]*\))?\s*\{/.test(snippet)) {
    kind = 'struct';
  } else if (/\bunion\s*(?:\([^)]*\))?\s*\{/.test(snippet)) {
    kind = 'union';
  } else if (/\benum\s*(?:\([^)]*\))?\s*\{/.test(snippet)) {
    kind = 'enum';
  } else if (/\berror\s*\{/.test(snippet)) {
    kind = 'error-set';
  } else if (expression && /^[A-Za-z_][A-Za-z0-9_.]*$/.test(expression)) {
    kind = 'alias';
  } else if (!expression) {
    kind = 'unknown';
  }

  return {
    name,
    kind,
    filePath,
    line,
    snippet,
    expression,
    importPath: importMatch?.[1],
    importMember: importMatch?.[2],
    enumValues: kind === 'enum' ? extractEnumValues(snippet) : [],
    structFields: kind === 'struct' ? extractStructFields(snippet) : kind === 'union' ? extractUnionFields(snippet) : [],
    errorMembers: kind === 'error-set' ? extractErrorMembers(snippet) : [],
  };
}

function findDeclaration(scope: SourceScope, name: string, publicOnly: boolean): Declaration | null {
  const lines = scope.content.split('\n');
  const visibility = publicOnly ? 'pub\\s+' : '(?:pub\\s+)?';
  const pattern = new RegExp(`^\\s*${visibility}(?:inline\\s+|noinline\\s+|export\\s+|extern\\s+)*(?:const|fn|var)\\s+${escapeRegExp(name)}\\b`);

  for (let i = 0; i < lines.length; i += 1) {
    if (!pattern.test(lines[i])) continue;

    const snippet = collectDeclaration(lines, i);
    return analyzeDeclaration(name, snippet, scope.filePath, scope.lineOffset + i + 1);
  }

  return null;
}

function listPublicDeclarations(scope: SourceScope): Declaration[] {
  const lines = scope.content.split('\n');
  const pattern = /^\s*pub\s+(?:inline\s+|noinline\s+|export\s+|extern\s+)*(?:const|fn|var)\s+([A-Za-z_][A-Za-z0-9_]*)\b/;
  const declarations: Declaration[] = [];
  let braceDepth = 0;

  for (let i = 0; i < lines.length; i += 1) {
    if (braceDepth !== 0) {
      braceDepth += braceDelta(lines[i]);
      continue;
    }

    const match = lines[i].match(pattern);
    if (!match) {
      braceDepth += braceDelta(lines[i]);
      continue;
    }

    const snippet = collectDeclaration(lines, i);
    declarations.push(analyzeDeclaration(match[1], snippet, scope.filePath, scope.lineOffset + i + 1));
    i += snippet.split('\n').length - 1;
  }

  return declarations;
}

function findPublicDeclaration(scope: SourceScope, name: string): Declaration | null {
  return findDeclaration(scope, name, true);
}

function findAnyDeclaration(scope: SourceScope, name: string): Declaration | null {
  return findDeclaration(scope, name, false);
}

function loadScope(filePath: string, description: string): SourceScope {
  return {
    filePath,
    content: fs.readFileSync(filePath, 'utf8'),
    lineOffset: 0,
    description,
  };
}

function scopeFromDeclaration(declaration: Declaration, description: string): SourceScope | null {
  const body = extractBalancedBody(declaration.snippet);
  if (!body) return null;

  const beforeBody = declaration.snippet.slice(0, declaration.snippet.indexOf('{'));
  const lineDelta = beforeBody.split('\n').length - 1;

  return {
    filePath: declaration.filePath,
    content: body,
    lineOffset: declaration.line + lineDelta,
    description,
    ownerDeclaration: declaration,
  };
}

function resolveImport(scope: SourceScope, declaration: Declaration): SourceScope | null {
  if (!declaration.importPath) return null;

  const importedPath = path.resolve(path.dirname(scope.filePath), declaration.importPath);
  if (!fs.existsSync(importedPath)) return null;

  const importedScope = loadScope(importedPath, `${declaration.name} import`);
  if (!declaration.importMember) return importedScope;

  const importedMember = findPublicDeclaration(importedScope, declaration.importMember);
  if (!importedMember) return importedScope;

  return scopeFromDeclaration(importedMember, `${declaration.name} import member`);
}

function resolveAliasScope(scope: SourceScope, declaration: Declaration): SourceScope | null {
  if (declaration.kind !== 'alias' || !declaration.expression) return null;

  const parts = declaration.expression.split('.');
  if (parts.length < 2) return null;

  const first = findAnyDeclaration(scope, parts[0]);
  if (!first) return null;

  let aliasScope = resolveImport(scope, first) ?? scopeFromDeclaration(first, `${first.name} alias body`);
  if (!aliasScope) return null;

  let target: Declaration | null = null;
  for (let index = 1; index < parts.length; index += 1) {
    target = findPublicDeclaration(aliasScope, parts[index]);
    if (!target) return null;

    if (index === parts.length - 1) break;

    aliasScope = resolveImport(aliasScope, target) ?? scopeFromDeclaration(target, `${target.name} alias body`);
    if (!aliasScope) return null;
  }

  if (!target) return null;
  return resolveImport(aliasScope, target) ?? scopeFromDeclaration(target, `${target.name} alias target`);
}

function resolveMemberReference(
  symbol: string,
  parent: Declaration | null,
  memberName: string,
  trace: string[]
): ResolveResult | null {
  if (!parent) return null;

  const kind =
    (parent.kind === 'struct' || parent.kind === 'union') && parent.structFields.includes(memberName) ? 'field' :
    parent.kind === 'enum' && parent.enumValues.includes(memberName) ? 'enum-value' :
    parent.kind === 'error-set' && parent.errorMembers.includes(memberName) ? 'error-member' :
    null;

  if (!kind) return null;

  return {
    ok: true,
    symbol,
    declaration: {
      name: memberName,
      kind,
      filePath: parent.filePath,
      line: parent.line,
      snippet: memberName,
      expression: null,
      enumValues: [],
      structFields: [],
      errorMembers: [],
    },
    trace,
  };
}

function resolveStdSymbol(stdlibPath: string, symbol: string): ResolveResult {
  const trace: string[] = [];
  const parts = symbol.split('.');

  if (parts[0] !== 'std' || parts.length < 2) {
    return {
      ok: false,
      symbol,
      message: 'Only std.* symbols are supported',
      trace,
    };
  }

  let scope = loadScope(path.join(stdlibPath, 'std.zig'), 'std root');
  let lastDeclaration: Declaration | null = null;

  for (let index = 1; index < parts.length; index += 1) {
    const name = parts[index];
    const declaration = findPublicDeclaration(scope, name);

    if (!declaration) {
      if (index === parts.length - 1) {
        const memberResult = resolveMemberReference(symbol, scope.ownerDeclaration ?? lastDeclaration, name, trace);
        if (memberResult) return memberResult;
      }

      return {
        ok: false,
        symbol,
        message: `Could not find public declaration "${name}" in ${path.relative(stdlibPath, scope.filePath)} (${scope.description})`,
        trace,
      };
    }

    trace.push(`${parts.slice(0, index + 1).join('.')} -> ${path.relative(stdlibPath, declaration.filePath)}:${declaration.line} (${declaration.kind})`);
    lastDeclaration = declaration;

    if (index === parts.length - 1) {
      return {
        ok: true,
        symbol,
        declaration,
        trace,
      };
    }

    const importedScope = resolveImport(scope, declaration);
    if (importedScope) {
      scope = importedScope;
      continue;
    }

    const aliasScope = resolveAliasScope(scope, declaration);
    if (aliasScope) {
      scope = aliasScope;
      continue;
    }

    const nestedScope = scopeFromDeclaration(declaration, `${name} declaration body`);
    if (nestedScope) {
      scope = nestedScope;
      continue;
    }

    return {
      ok: false,
      symbol,
      declaration,
      message: `Cannot descend through ${parts.slice(0, index + 1).join('.')} (${declaration.kind})`,
      trace,
    };
  }

  return {
    ok: false,
    symbol,
    declaration: lastDeclaration ?? undefined,
    message: 'Symbol resolution ended unexpectedly',
    trace,
  };
}

function extractMarkdownSection(content: string, heading: string): string | null {
  const pattern = new RegExp(`^##\\s+${escapeRegExp(heading)}\\s*$`, 'mi');
  const match = pattern.exec(content);
  if (!match) return null;

  const start = match.index + match[0].length;
  const rest = content.slice(start);
  const nextHeading = rest.search(/^##\s+/m);
  return nextHeading >= 0 ? rest.slice(0, nextHeading) : rest;
}

function extractDocumentedListItems(content: string, heading: string): string[] {
  const section = extractMarkdownSection(content, heading);
  if (!section) return [];

  const values = new Set<string>();
  for (const line of section.split('\n')) {
    const headingMatch = line.match(/^###\s+`?([A-Za-z_][A-Za-z0-9_]*)`?/);
    if (headingMatch) values.add(headingMatch[1]);

    const bareMatch = line.match(/^`([A-Za-z_][A-Za-z0-9_]*)`\s*$/);
    if (bareMatch) values.add(bareMatch[1]);

    const bulletMatch = line.match(/^[-*]\s+`([A-Za-z_][A-Za-z0-9_]*)`/);
    if (bulletMatch) values.add(bulletMatch[1]);
  }

  return Array.from(values).sort();
}

function extractBacktickReferences(content: string): string[] {
  const references = new Set<string>();
  const pattern = /`([^`\n]+)`/g;
  let match: RegExpExecArray | null;

  while ((match = pattern.exec(content)) !== null) {
    const value = match[1].trim();
    if (value.endsWith('.md')) continue;
    if (/^std(?:\.[A-Za-z_][A-Za-z0-9_]*)+$/.test(value)) {
      references.add(value);
    }
  }

  return Array.from(references).sort();
}

function arraysEqual(left: string[], right: string[]): boolean {
  if (left.length !== right.length) return false;
  return left.every((value, index) => value === right[index]);
}

function compareNamedList(
  findings: AuditFinding[],
  file: string,
  symbol: string,
  declaration: Declaration,
  label: string,
  docValues: string[],
  sourceValues: string[]
): void {
  if (docValues.length === 0 || sourceValues.length === 0) return;

  const sortedDocValues = [...docValues].sort();
  const sortedSourceValues = [...sourceValues].sort();

  if (arraysEqual(sortedDocValues, sortedSourceValues)) return;

  const missingInDocs = sortedSourceValues.filter(value => !sortedDocValues.includes(value));
  const missingInSource = sortedDocValues.filter(value => !sortedSourceValues.includes(value));

  findings.push({
    severity: 'warning',
    code: `${label.toUpperCase()}_DRIFT`,
    file,
    symbol,
    message: `${label} documented in markdown differ from local stdlib source.`,
    source: {
      file: relativeToRepoIfInside(declaration.filePath),
      line: declaration.line,
      kind: declaration.kind,
    },
    details: [
      `source: ${sortedSourceValues.join(', ') || '(none)'}`,
      `docs: ${sortedDocValues.join(', ') || '(none)'}`,
      ...(missingInDocs.length > 0 ? [`missing in docs: ${missingInDocs.join(', ')}`] : []),
      ...(missingInSource.length > 0 ? [`not in source: ${missingInSource.join(', ')}`] : []),
    ],
  });
}

function relativeToRepoIfInside(filePath: string): string {
  const relativePath = path.relative(REPO_ROOT, filePath);
  return relativePath.startsWith('..') ? filePath : relativePath;
}

function auditMarkdownFile(stdlibPath: string, filePath: string): AuditFinding[] {
  const content = fs.readFileSync(filePath, 'utf8');
  const file = relativeToRepo(filePath);
  const symbol = inferSymbol(filePath, content);
  const findings: AuditFinding[] = [];

  if (!symbol) {
    return [{
      severity: 'skipped',
      code: 'NO_STD_SYMBOL',
      file,
      symbol: null,
      message: 'Could not infer a std.* symbol from the markdown H1 or filename.',
    }];
  }

  const resolved = resolveStdSymbol(stdlibPath, symbol);
  if (!resolved.ok || !resolved.declaration) {
    return [{
      severity: 'error',
      code: 'MISSING_SYMBOL',
      file,
      symbol,
      message: resolved.message ?? 'Symbol was not found in local stdlib source.',
      details: resolved.trace,
    }];
  }

  const declaration = resolved.declaration;
  findings.push({
    severity: 'ok',
    code: 'SYMBOL_FOUND',
    file,
    symbol,
    message: `Resolved ${symbol} as ${declaration.kind}.`,
    source: {
      file: relativeToRepoIfInside(declaration.filePath),
      line: declaration.line,
      kind: declaration.kind,
    },
    details: resolved.trace,
  });

  compareNamedList(
    findings,
    file,
    symbol,
    declaration,
    'values',
    extractDocumentedListItems(content, 'Values'),
    declaration.enumValues
  );

  compareNamedList(
    findings,
    file,
    symbol,
    declaration,
    'fields',
    extractDocumentedListItems(content, 'Fields'),
    declaration.structFields
  );

  compareNamedList(
    findings,
    file,
    symbol,
    declaration,
    'errors',
    extractDocumentedListItems(content, 'Error Set'),
    declaration.errorMembers
  );

  for (const reference of extractBacktickReferences(content)) {
    if (reference === symbol) continue;
    const referenceResult = resolveStdSymbol(stdlibPath, reference);
    if (!referenceResult.ok) {
      findings.push({
        severity: 'warning',
        code: 'UNRESOLVED_REFERENCE',
        file,
        symbol,
        message: `Backticked reference ${reference} does not resolve in local stdlib source.`,
        details: referenceResult.trace.length > 0 ? referenceResult.trace : [referenceResult.message ?? 'No resolver details available.'],
      });
    }
  }

  return findings;
}

function collectDocumentedSymbols(files: string[]): Map<string, string> {
  const documentedSymbols = new Map<string, string>();

  for (const filePath of files) {
    const content = fs.readFileSync(filePath, 'utf8');
    const symbol = inferSymbol(filePath, content);
    if (symbol) documentedSymbols.set(symbol, relativeToRepo(filePath));
  }

  return documentedSymbols;
}

function shouldRunCoverageRule(inputPaths: string[], rule: CoverageRule): boolean {
  const ruleRoot = resolveRepoPath(rule.docRoot);

  return inputPaths.some(inputPath => {
    const absolutePath = resolveRepoPath(inputPath);
    if (pathContains(absolutePath, ruleRoot)) return true;
    if (!fs.existsSync(absolutePath)) return false;
    return fs.statSync(absolutePath).isDirectory() && pathContains(ruleRoot, absolutePath);
  });
}

function shouldRunRootCoverageCategory(inputPaths: string[], docRoot: string): boolean {
  const ruleRoot = resolveRepoPath(docRoot);

  return inputPaths.some(inputPath => {
    const absolutePath = resolveRepoPath(inputPath);
    return pathContains(absolutePath, ruleRoot);
  });
}

function expectedDocPath(rule: CoverageRule, symbol: string): string {
  return path.join(rule.expectedDir, `${symbol}.md`);
}

function expectedRootDocPath(category: RootDeclarationCategory, expectedDir: string, symbol: string): string {
  if (category === 'Types' || category === 'Namespaces') {
    const name = symbol.slice('std.'.length);
    return path.join(expectedDir, name, `${symbol}.md`);
  }

  return path.join(expectedDir, `${symbol}.md`);
}

function classifyRootDeclaration(declaration: Declaration): RootDeclarationCategory {
  if (declaration.name === 'options') return 'Values';
  return /^[a-z]/.test(declaration.name) ? 'Namespaces' : 'Types';
}

function auditCoverageRules(
  stdlibPath: string,
  options: CliOptions,
  documentedSymbols: Map<string, string>
): AuditFinding[] {
  const findings: AuditFinding[] = [];

  for (const rule of COVERAGE_RULES) {
    if (!shouldRunCoverageRule(options.paths, rule)) continue;

    for (const name of rule.symbols) {
      const symbol = `${rule.namespace}.${name}`;
      if (documentedSymbols.has(symbol)) continue;

      const resolved = resolveStdSymbol(stdlibPath, symbol);
      if (!resolved.ok || !resolved.declaration) {
        findings.push({
          severity: 'warning',
          code: 'COVERAGE_SYMBOL_UNRESOLVED',
          file: expectedDocPath(rule, symbol),
          symbol,
          message: 'Coverage rule references a symbol that does not resolve in local stdlib source.',
          details: resolved.trace.length > 0 ? resolved.trace : [resolved.message ?? 'No resolver details available.'],
        });
        continue;
      }

      findings.push({
        severity: 'error',
        code: 'MISSING_DOC',
        file: expectedDocPath(rule, symbol),
        symbol,
        message: `Public ${rule.namespace} declaration has no markdown documentation file.`,
        source: {
          file: relativeToRepoIfInside(resolved.declaration.filePath),
          line: resolved.declaration.line,
          kind: resolved.declaration.kind,
        },
        details: resolved.trace,
      });
    }
  }

  return findings;
}

function auditRootCoverageRules(
  stdlibPath: string,
  options: CliOptions,
  documentedSymbols: Map<string, string>
): AuditFinding[] {
  const findings: AuditFinding[] = [];

  for (const rule of ROOT_COVERAGE_RULES) {
    const categoryConfigs = rule.categories.filter(category =>
      shouldRunRootCoverageCategory(options.paths, category.docRoot)
    );
    if (categoryConfigs.length === 0) continue;

    const categoryByName = new Map(categoryConfigs.map(category => [category.category, category]));
    const sourceScope = loadScope(path.join(stdlibPath, rule.sourceFile), `${rule.namespace} root`);
    const declarations = listPublicDeclarations(sourceScope);

    for (const declaration of declarations) {
      const category = classifyRootDeclaration(declaration);
      const categoryConfig = categoryByName.get(category);
      if (!categoryConfig) continue;

      const symbol = `${rule.namespace}.${declaration.name}`;
      if (documentedSymbols.has(symbol)) continue;

      findings.push({
        severity: 'error',
        code: 'MISSING_DOC',
        file: expectedRootDocPath(category, categoryConfig.expectedDir, symbol),
        symbol,
        message: `Public ${rule.namespace} ${category.slice(0, -1).toLowerCase()} declaration has no markdown documentation file.`,
        source: {
          file: relativeToRepoIfInside(declaration.filePath),
          line: declaration.line,
          kind: declaration.kind,
        },
        details: [
          `${symbol} -> ${path.relative(stdlibPath, declaration.filePath)}:${declaration.line} (${declaration.kind})`,
        ],
      });
    }
  }

  return findings;
}

function summarize(findings: AuditFinding[]): AuditSummary {
  return findings.reduce<AuditSummary>((summary, finding) => {
    summary.checked += finding.code === 'SYMBOL_FOUND' || finding.code === 'MISSING_SYMBOL' || finding.code === 'MISSING_DOC' || finding.code === 'NO_STD_SYMBOL' ? 1 : 0;
    if (finding.severity === 'ok') summary.ok += 1;
    if (finding.severity === 'warning') summary.warnings += 1;
    if (finding.severity === 'error') summary.errors += 1;
    if (finding.severity === 'skipped') summary.skipped += 1;
    return summary;
  }, {
    checked: 0,
    ok: 0,
    warnings: 0,
    errors: 0,
    skipped: 0,
  });
}

function formatFinding(finding: AuditFinding): string {
  const location = finding.source
    ? ` (${finding.source.file}:${finding.source.line})`
    : '';
  const symbol = finding.symbol ? ` ${finding.symbol}` : '';
  const details = finding.details && finding.details.length > 0
    ? `\n    ${finding.details.join('\n    ')}`
    : '';

  return `${finding.severity.toUpperCase().padEnd(7)} ${finding.code}${symbol} - ${finding.file}${location}\n    ${finding.message}${details}`;
}

function printTextReport(findings: AuditFinding[], summary: AuditSummary, options: CliOptions): void {
  const visibleFindings = findings
    .filter(finding => options.includeOk || finding.severity !== 'ok')
    .slice(0, options.maxFindings);

  console.log('# Zig Stdlib Docs Audit');
  console.log(`Checked: ${summary.checked}`);
  console.log(`OK: ${summary.ok}`);
  console.log(`Warnings: ${summary.warnings}`);
  console.log(`Errors: ${summary.errors}`);
  console.log(`Skipped: ${summary.skipped}`);

  if (visibleFindings.length === 0) {
    console.log('\nNo findings to print. Use --include-ok to show successful symbol resolutions.');
    return;
  }

  console.log('');
  for (const finding of visibleFindings) {
    console.log(formatFinding(finding));
  }

  const hidden = findings.filter(finding => options.includeOk || finding.severity !== 'ok').length - visibleFindings.length;
  if (hidden > 0) {
    console.log(`\n... ${hidden} more findings hidden by --max ${options.maxFindings}`);
  }
}

function main(): void {
  const options = parseArgs(process.argv.slice(2));
  const contract = loadContract();
  const stdlibPath = process.env[contract.stdlibSource.overrideEnvVar] || contract.stdlibSource.expectedPath;

  if (!fs.existsSync(stdlibPath)) {
    throw new Error(`Stdlib source path does not exist: ${stdlibPath}`);
  }

  const files = walkMarkdownFiles(options.paths);
  const documentedSymbols = collectDocumentedSymbols(files);
  const findings = [
    ...files.flatMap(file => auditMarkdownFile(stdlibPath, file)),
    ...auditRootCoverageRules(stdlibPath, options, documentedSymbols),
    ...auditCoverageRules(stdlibPath, options, documentedSymbols),
  ];
  const summary = summarize(findings);

  if (options.json) {
    console.log(JSON.stringify({
      targetZigVersion: contract.targetZigVersion,
      stdlibPath,
      summary,
      findings,
    }, null, 2));
  } else {
    console.log(`Target Zig: ${contract.targetZigVersion}`);
    console.log(`Stdlib Source: ${stdlibPath}\n`);
    printTextReport(findings, summary, options);
  }

  if (options.failOnIssues && (summary.warnings > 0 || summary.errors > 0)) {
    process.exitCode = 1;
  }
}

try {
  main();
} catch (error: any) {
  console.error(`audit-stdlib-docs failed: ${error.message}`);
  process.exitCode = 1;
}
