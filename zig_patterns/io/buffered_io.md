# Pattern: Buffered I/O

**Problem**: How to efficiently read/write data without excessive system calls?

**When to use**:
- Reading from files or network sockets line-by-line
- Writing large amounts of data to files or streams
- Processing streaming data with backpressure
- When I/O performance matters

**Alternatives**:
- Unbuffered I/O (many system calls, slow)
- Loading entire file into memory (not viable for large files)
- Manual buffer management (complex, error-prone)

---

## Basic Example: Buffered Reading

```zig
// TODO: Add buffered reader example
```

---

## Pattern: Buffered Writing

```zig
// TODO: Add buffered writer example
```

---

## Real-World Example: Line-by-Line Processing

```zig
// TODO: Add log file processor with buffered reader
```

---

## Common Mistakes

- ❌ **Forgetting to flush writer**: Data stuck in buffer
- ❌ **Buffer too small**: Defeats purpose of buffering
- ❌ **Buffer too large**: Wastes memory, may cause issues with stack allocation

---

## Performance Tips

1. **Choose buffer size wisely**: 4KB-64KB is typical
2. **Always flush before closing**: Use defer for safety
3. **Reuse buffers when possible**: Avoid repeated allocation

---

## See Also

- [Defer Cleanup Pattern](../memory/defer_cleanup.md)
