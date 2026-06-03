import { describe, test, expect, beforeAll } from 'vitest';
import { ZigDocumentationServer } from './index.js';

describe('ZigDocumentationServer', () => {
  let server: ZigDocumentationServer;

  beforeAll(async () => {
    server = new ZigDocumentationServer();
    await server['loadDocsIntoCache']();
  });

  describe('URI to File Path Conversion', () => {
    test('converts language doc URIs correctly', () => {
      const filePath = server['uriToFilePath']('zig://doc/comptime');
      expect(filePath).toBe('zig_docs/comptime.md');
    });

    test('converts doc URIs with hyphens', () => {
      const filePath = server['uriToFilePath']('zig://doc/build-mode');
      expect(filePath).toBe('zig_docs/build_mode.md');
    });

    test('converts prose doc URIs with hyphens to underscore filenames', () => {
      expect(server['uriToFilePath']('zig://doc/zig-build-system')).toBe('zig_docs/zig_build_system.md');
      expect(server['uriToFilePath']('zig://doc/zig-standard-library')).toBe('zig_docs/zig_standard_library.md');
    });

    test('converts std library type URIs', () => {
      const filePath = server['uriToFilePath']('zig://std/Types/ArrayList/ArrayList');
      expect(filePath).toBe('zig_docs_std/Types/ArrayList/ArrayList.md');
    });

    test('converts nested std library URIs', () => {
      const filePath = server['uriToFilePath']('zig://std/Types/Io/Types/std.Io.Writer');
      expect(filePath).toBe('zig_docs_std/Types/Io/Types/std.Io.Writer.md');
    });

    test('converts example URIs', () => {
      const filePath = server['uriToFilePath']('zig://examples/arraylist');
      expect(filePath).toBe('zig_docs_std/Examples/test_arraylist.zig');
    });

    test('converts example URIs for non-test-prefixed files', () => {
      const filePath = server['uriToFilePath']('zig://examples/arrays.tests');
      expect(filePath).toBe('zig_docs_std/Examples/arrays.tests.zig');
    });

    test('converts index URIs', () => {
      const filePath = server['uriToFilePath']('zig://std/index');
      expect(filePath).toBe('zig_docs_std/index.md');
    });

    test('throws error for unknown URI format', () => {
      expect(() => server['uriToFilePath']('unknown://invalid')).toThrow('Unknown URI format');
    });
  });

  describe('Search Functionality', () => {
    test('finds documents with exact match', () => {
      const result = server['searchDocumentation']('comptime');
      expect(result).toContain('comptime');
      expect(result).toContain('zig://doc/comptime');
    });

    test('finds documents with partial match', () => {
      const result = server['searchDocumentation']('array');
      expect(result.toLowerCase()).toContain('array');
    });

    test('finds prose language docs for build system and standard library queries', () => {
      const buildResult = server['searchDocumentation']('zig build system');
      expect(buildResult).toContain('zig://doc/zig_build_system');

      const stdlibResult = server['searchDocumentation']('zig standard library');
      expect(stdlibResult).toContain('zig://doc/zig_standard_library');
    });

    test('returns helpful message for no matches', () => {
      const result = server['searchDocumentation']('xyznonexistentquery123');
      expect(result).toContain('No documentation found');
      expect(result).toContain('Try searching for');
    });

    test('limits results to top 10', () => {
      const result = server['searchDocumentation']('the');
      const uriMatches = result.match(/URI: zig:\/\//g);
      expect(uriMatches?.length).toBeLessThanOrEqual(10);
    });
  });

  describe('Match Scoring Algorithm', () => {
    test('exact filename match scores highest', () => {
      const exactScore = server['calculateMatchScore'](
        'arraylist',
        'arraylist',
        'ArrayList',
        'ArrayList documentation content'
      );
      const partialScore = server['calculateMatchScore'](
        'arraylist',
        'array',
        'Array',
        'Array documentation content'
      );
      expect(exactScore).toBeGreaterThan(partialScore);
    });

    test('exact resource name match scores high', () => {
      const score = server['calculateMatchScore'](
        'ArrayList',
        'arraylist',
        'ArrayList',
        'content'
      );
      expect(score).toBeGreaterThan(80);
    });

    test('content-only match scores lower', () => {
      const filenameScore = server['calculateMatchScore'](
        'test',
        'test',
        'Test',
        'content'
      );
      const contentScore = server['calculateMatchScore'](
        'test',
        'other',
        'Other',
        'test in content'
      );
      expect(filenameScore).toBeGreaterThan(contentScore);
    });

    test('fuzzy matching with Levenshtein distance', () => {
      const score = server['calculateMatchScore'](
        'arrylist',  // typo: missing 'a'
        'arraylist',
        'ArrayList',
        'content'
      );
      expect(score).toBeGreaterThan(0);
    });

    test('no match returns zero score', () => {
      const score = server['calculateMatchScore'](
        'completelydifferent',
        'arraylist',
        'ArrayList',
        'content about lists'
      );
      expect(score).toBe(0);
    });
  });

  describe('Levenshtein Distance', () => {
    test('identical strings have distance 0', () => {
      const distance = server['levenshteinDistance']('test', 'test');
      expect(distance).toBe(0);
    });

    test('single character insertion', () => {
      const distance = server['levenshteinDistance']('test', 'tests');
      expect(distance).toBe(1);
    });

    test('single character deletion', () => {
      const distance = server['levenshteinDistance']('tests', 'test');
      expect(distance).toBe(1);
    });

    test('single character substitution', () => {
      const distance = server['levenshteinDistance']('test', 'text');
      expect(distance).toBe(1);
    });

    test('multiple edits', () => {
      const distance = server['levenshteinDistance']('kitten', 'sitting');
      expect(distance).toBe(3);
    });
  });

  describe('Word Splitting', () => {
    test('splits camelCase', () => {
      const words = server['splitWords']('camelCase');
      expect(words).toContain('camel');
      expect(words).toContain('Case');
    });

    test('splits PascalCase', () => {
      const words = server['splitWords']('PascalCase');
      expect(words).toContain('Pascal');
      expect(words).toContain('Case');
    });

    test('splits snake_case', () => {
      const words = server['splitWords']('snake_case');
      expect(words).toContain('snake');
      expect(words).toContain('case');
    });

    test('splits kebab-case', () => {
      const words = server['splitWords']('kebab-case');
      expect(words).toContain('kebab');
      expect(words).toContain('case');
    });

    test('handles mixed formats', () => {
      const words = server['splitWords']('MyClass_withMethod');
      expect(words).toContain('My');
      expect(words).toContain('Class');
      expect(words).toContain('with');
      expect(words).toContain('Method');
    });
  });

  describe('Helper Methods', () => {
    test('extractAllBuiltins finds builtin functions', () => {
      const content = `
### @import
Documentation for import

### @sizeof
Documentation for sizeof

### @typeInfo
Documentation for typeInfo
      `.trim();

      const builtins = server['extractAllBuiltins'](content);
      expect(builtins).toContain('@import');
      expect(builtins).toContain('@sizeof');
      expect(builtins).toContain('@typeInfo');
      expect(builtins.length).toBe(3);
    });

    test('findSimilarStrings returns closest matches', () => {
      const candidates = ['@import', '@export', '@sizeof', '@typeInfo', '@alignOf'];
      const similar = server['findSimilarStrings']('@imprt', candidates, 3);

      expect(similar).toContain('@import');
      expect(similar.length).toBeLessThanOrEqual(3);
    });

    test('findSimilarStrings filters by edit distance threshold', () => {
      const candidates = ['arraylist', 'hashmap', 'vector'];
      const similar = server['findSimilarStrings']('xyz', candidates, 5);

      // No matches should be found (all have edit distance > 3)
      expect(similar.length).toBe(0);
    });
  });

  describe('Version Contract', () => {
    test('loads the repo-local Zig version contract', () => {
      const contract = server['versionContract'];

      expect(contract.targetZigVersion).toBe('0.16.0');
      expect(contract.stdlibSource.expectedPath).toContain('zig-0.16.0');
      expect(contract.stdlibSource.overrideEnvVar).toBe('ZIG_DOCS_STDLIB_SOURCE');
      expect(contract.upgradePolicy).toContain('explicit upgrade ticket');
    });

    test('rejects local Zig version drift until the MCP target is upgraded', () => {
      const mismatch = server['checkZigVersionContract'](
        { version: '0.16.1', stdDir: '/tmp/zig-0.16.1/lib/std' }
      );

      expect(mismatch.ok).toBe(false);
      expect(mismatch.status).toBe('mismatch');
      expect(mismatch.message).toContain('Retarget this MCP');
      expect(mismatch.message).toContain('explicit upgrade ticket');
    });

    test('local Zig version satisfies the contract', () => {
      const check = server['checkZigVersionContract']();

      expect(check.targetVersion).toBe('0.16.0');
      expect(check.ok).toBe(true);
    });
  });

  describe('Diagnostics', () => {
    test('getDiagnostics returns server information', () => {
      const diagnostics = server['getDiagnostics'](false);

      expect(diagnostics).toContain('Server Diagnostics');
      expect(diagnostics).toContain('Server Name');
      expect(diagnostics).toContain('Server Version');
      expect(diagnostics).toContain('Zig Version Contract');
      expect(diagnostics).toContain('Target Zig Version');
      expect(diagnostics).toContain('0.16.0');
      expect(diagnostics).toContain('Cache Status');
      expect(diagnostics).toContain('Documentation Breakdown');
    });

    test('getDiagnostics includes samples when requested', () => {
      const diagnostics = server['getDiagnostics'](true);

      expect(diagnostics).toContain('Sample Resources');
      expect(diagnostics).toContain('Language Documentation');
      expect(diagnostics).toContain('Standard Library');
      expect(diagnostics).toContain('Examples');
    });

    test('getDiagnostics excludes samples by default', () => {
      const diagnostics = server['getDiagnostics'](false);

      expect(diagnostics).not.toContain('Sample Resources');
    });

    test('getDiagnostics shows correct resource counts', () => {
      const diagnostics = server['getDiagnostics'](false);

      // Should have resources loaded
      expect(diagnostics).toMatch(/\*\*Total Resources:\*\* \d+/);
      expect(diagnostics).toMatch(/\*\*Language Docs:\*\* \d+ files/);
      expect(diagnostics).toMatch(/\*\*Standard Library Docs:\*\* \d+ files/);
      expect(diagnostics).toMatch(/\*\*Working Examples:\*\* \d+ files/);
    });
  });

  describe('Cache Behavior', () => {
    test('documentation is loaded into cache', () => {
      const cacheSize = server['docCache'].size;
      expect(cacheSize).toBeGreaterThan(0);
    });

    test('resource list is populated', () => {
      const resourceCount = server['resourceList'].length;
      expect(resourceCount).toBeGreaterThan(0);
    });

    test('language docs are cached', () => {
      const langDocs = server['resourceList'].filter(r =>
        r.uri.startsWith('zig://doc/')
      );
      expect(langDocs.length).toBeGreaterThan(0);
    });

    test('prose language docs are cached as resources', () => {
      expect(server['resourceList']).toEqual(expect.arrayContaining([
        expect.objectContaining({
          uri: 'zig://doc/zig_build_system',
          name: 'Zig_build_system',
        }),
        expect.objectContaining({
          uri: 'zig://doc/zig_standard_library',
          name: 'Zig_standard_library',
        }),
      ]));
    });

    test('stdlib docs are cached', () => {
      const stdDocs = server['resourceList'].filter(r =>
        r.uri.startsWith('zig://std/')
      );
      expect(stdDocs.length).toBeGreaterThan(0);
    });

    test('examples are cached', () => {
      const examples = server['resourceList'].filter(r =>
        r.uri.startsWith('zig://examples/')
      );
      expect(examples.length).toBeGreaterThan(0);
    });
  });

  describe('Format Resource Name', () => {
    test('formats doc URIs correctly', () => {
      const name = server['formatResourceName']('zig://doc/comptime');
      expect(name).toBe('Comptime');
    });

    test('formats doc URIs with hyphens', () => {
      const name = server['formatResourceName']('zig://doc/build-mode');
      expect(name).toBe('Build Mode');
    });

    test('formats type URIs correctly', () => {
      const name = server['formatResourceName']('zig://std/Types/ArrayList/ArrayList');
      expect(name).toBe('Types.ArrayList.ArrayList');
    });

    test('formats namespace URIs correctly', () => {
      const name = server['formatResourceName']('zig://std/Namespaces/std.Io.net/net');
      expect(name).toBe('Namespaces.std.Io.net.net');
    });

    test('formats example URIs correctly', () => {
      const name = server['formatResourceName']('zig://examples/arraylist');
      expect(name).toBe('Example: arraylist');
    });

    test('formats index URI correctly', () => {
      const name = server['formatResourceName']('zig://std/index');
      expect(name).toBe('index');
    });
  });

  describe('Error Handling', () => {
    test('getBuiltinInfo handles non-existent builtin gracefully', async () => {
      const result = await server['getBuiltinInfo']('@nonexistent');

      expect(result).toContain('not found');
      expect(result).toContain('Troubleshooting');
      expect(result).toContain('Builtin functions start with @');
    });

    test('getBuiltinInfo suggests similar builtins when available', async () => {
      const result = await server['getBuiltinInfo']('@imprt');  // Close to @import

      expect(result).toContain('not found');
      expect(result).toContain('Did you mean');
      expect(result).toContain('@import');
    });

    test('explainConcept handles non-existent concept gracefully', async () => {
      const result = await server['explainConcept']('xyznonexistent');

      expect(result).toContain('not found');
      expect(result).toContain('Available concepts');
    });

    test('explainConcept finds partial matches', async () => {
      const result = await server['explainConcept']('comptim');  // Close to comptime

      // Should find related concept
      expect(result.toLowerCase()).toContain('comptime');
    });

    test('searchDocumentation handles empty query', () => {
      const result = server['searchDocumentation']('');
      expect(result).toBeDefined();
    });
  });
});
