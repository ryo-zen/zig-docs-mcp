# Documentation Update Plan - std.Io Network Types

## Completed ✅

1. **std.Io.Terminal.md** - COMPLETE
   - Reformatted to standard structure
   - 10 comprehensive tests created
   - All API verified and corrected
   - Test file: `test_terminal_comprehensive.zig`

2. **std.Io.LockedStderr.md** - COMPLETE
   - Complete rewrite with standard structure
   - 15 comprehensive tests created
   - All API verified and corrected
   - Known issues documented (tryLockStderr bug)
   - Test file: `test_locked_stderr_comprehensive.zig`

## Pending Tasks

### Phase 1: Network Address Types (High Priority)

#### 1. std.Io.net.UnixAddress.md (461 B)
**Current Status:** Minimal documentation
**Tasks:**
- [ ] Read current documentation
- [ ] Research actual API in Zig stdlib (`/opt/zig-.../lib/std/Io/net/UnixAddress.zig`)
- [ ] Identify all public functions and fields
- [ ] Reformat following standard structure:
  - Quick Start section (most common patterns)
  - Overview with Key Characteristics
  - Fields section with detailed descriptions
  - Functions by category
  - Usage Patterns (path handling, abstract sockets, etc.)
  - Error Sets
  - Debug Checklist
  - Performance Tips
  - See Also
- [ ] Create comprehensive test file: `test_unix_address_comprehensive.zig`
  - Test path-based Unix sockets
  - Test abstract namespace sockets (Linux)
  - Test path length limits
  - Test address parsing/formatting
  - Test all documented code examples
- [ ] Run tests and verify all pass
- [ ] Update documentation with corrected API

**Estimated Tests:** 8-10 tests

---

#### 2. std.Io.net.IncomingMessage.md (489 B)
**Current Status:** Minimal documentation
**Tasks:**
- [ ] Read current documentation
- [ ] Research actual API in Zig stdlib
- [ ] Identify all public functions and fields
- [ ] Reformat following standard structure:
  - Quick Start (reading headers, body, etc.)
  - Overview with Key Characteristics
  - Fields section
  - Functions by category (header access, body reading, etc.)
  - Usage Patterns (HTTP server patterns)
  - Error Sets
  - Debug Checklist
  - Performance Tips
  - See Also
- [ ] Create comprehensive test file: `test_incoming_message_comprehensive.zig`
  - Test header reading
  - Test body reading
  - Test chunked encoding
  - Test content-length handling
  - Test all documented code examples
- [ ] Run tests and verify all pass
- [ ] Update documentation with corrected API

**Estimated Tests:** 10-12 tests

---

#### 3. std.Io.net.OutgoingMessage.md (281 B)
**Current Status:** Minimal documentation
**Tasks:**
- [ ] Read current documentation
- [ ] Research actual API in Zig stdlib
- [ ] Identify all public functions and fields
- [ ] Reformat following standard structure:
  - Quick Start (writing headers, body, etc.)
  - Overview with Key Characteristics
  - Fields section
  - Functions by category (header writing, body writing, etc.)
  - Usage Patterns (HTTP client patterns)
  - Error Sets
  - Debug Checklist
  - Performance Tips
  - See Also
- [ ] Create comprehensive test file: `test_outgoing_message_comprehensive.zig`
  - Test header writing
  - Test body writing
  - Test chunked encoding
  - Test content-length handling
  - Test response building
  - Test all documented code examples
- [ ] Run tests and verify all pass
- [ ] Update documentation with corrected API

**Estimated Tests:** 10-12 tests

---

#### 4. std.Io.net.Interface.md (349 B)
**Current Status:** Minimal documentation
**Tasks:**
- [ ] Read current documentation
- [ ] Research actual API in Zig stdlib
- [ ] Identify all public functions and fields
- [ ] Reformat following standard structure:
  - Quick Start (enumerating interfaces, getting addresses, etc.)
  - Overview with Key Characteristics
  - Fields section
  - Functions by category (enumeration, address access, etc.)
  - Usage Patterns (network interface discovery)
  - Error Sets
  - Debug Checklist
  - Performance Tips
  - See Also
- [ ] Create comprehensive test file: `test_interface_comprehensive.zig`
  - Test interface enumeration
  - Test address retrieval
  - Test interface properties
  - Test platform differences (Linux, Windows, macOS)
  - Test all documented code examples
- [ ] Run tests and verify all pass
- [ ] Update documentation with corrected API

**Estimated Tests:** 8-10 tests

---

### Phase 2: OS Backend (Low Priority)

#### 5. std.Io.IoUring.md (371 B)
**Current Status:** Minimal documentation - OS Backend
**Priority:** Low (specialized Linux feature)
**Tasks:**
- [ ] Read current documentation
- [ ] Research actual API in Zig stdlib
- [ ] Identify all public functions and fields
- [ ] Reformat following standard structure:
  - Quick Start (basic io_uring setup)
  - Overview with Key Characteristics
  - Fields section
  - Functions by category
  - Usage Patterns (async I/O patterns)
  - Error Sets
  - Debug Checklist
  - Performance Tips
  - Platform Requirements (Linux 5.1+)
  - See Also
- [ ] Create comprehensive test file: `test_io_uring_comprehensive.zig`
  - Test basic submission queue operations
  - Test completion queue operations
  - Test async file operations
  - Test async socket operations
  - Test all documented code examples
  - **Note:** Tests may need Linux kernel checks
- [ ] Run tests and verify all pass (on Linux only)
- [ ] Update documentation with corrected API

**Estimated Tests:** 12-15 tests (Linux-specific)

---

## Standard Structure Template

All documentation files should follow this structure:

```markdown
# [Type Name]

📚 **[See Comprehensive Examples & Tests](../../Examples/test_xxx_comprehensive.zig)**

## Quick Start

### Most Common Patterns
[3-5 common use cases with code]

### Key Operations
[Bullet list of main operations]

### ⚠️ Critical: [Important Warning]
[Key warning or gotcha]

---

## Overview

[2-3 paragraph description]

**Key Characteristics:**
- [Bullet points]

**When to use [Type]:**
- [Bullet points]

## Fields

[Detailed field descriptions with separators]

## Types / Nested Types

[Type descriptions]

## [Category] Functions

### `function_signature`

[Description]

**Parameters:**
[List]

**Returns:**
[Description]

**Example:**
```zig
[Working code example]
```

------

[More functions...]

## Usage Patterns

### Pattern 1: [Name]
[Complete working example]

## Error Sets

[Error descriptions]

## Debug Checklist

[6-8 common issues with solutions]

## Performance Tips

[4-6 performance recommendations]

## See Also

[Related documentation links]
```

## Testing Strategy

For each file:
1. **API Research:** Use `grep` to find the actual type definition in Zig stdlib
2. **Example Creation:** Write 8-15 comprehensive tests covering:
   - Basic usage
   - All documented patterns
   - Error handling
   - Edge cases
   - Platform differences (if applicable)
3. **Verification:** Run tests and fix any API mismatches
4. **Documentation Update:** Update docs with verified API

## Success Criteria

For each file:
- ✅ Follows standard structure (matching Reader.md)
- ✅ All code examples are tested and working
- ✅ Comprehensive test file created (8-15 tests)
- ✅ All tests pass
- ✅ API verified against actual Zig stdlib
- ✅ Debug checklist with practical advice
- ✅ Performance tips included
- ✅ Known issues documented (if any)

## Timeline Estimate

- **UnixAddress:** 1-2 hours (simpler type)
- **IncomingMessage:** 2-3 hours (HTTP complexity)
- **OutgoingMessage:** 2-3 hours (HTTP complexity)
- **Interface:** 1-2 hours (platform differences)
- **IoUring:** 3-4 hours (complex async I/O, Linux-only)

**Total Estimate:** 9-14 hours for all 5 files

## Notes

- Keep Terminal and LockedStderr as reference examples
- Use `std.Io.Reader.md` as the canonical structure reference
- Test on Linux first (most complete I/O support)
- Document platform-specific behavior clearly
- Note any stdlib bugs discovered (like tryLockStderr)
