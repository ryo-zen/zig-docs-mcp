# Zig Patterns

Problem-oriented Zig coding patterns and idioms for practical development.

## Purpose

This directory contains **practical patterns** that solve common programming problems in Zig. Unlike reference documentation (which explains *what* types/functions do), patterns show *how* to solve real-world problems.

## 🧘 Start Here: [The Zen of Zig](zen.md)

Read the **[Zen of Zig](zen.md)** first to understand the guiding principles behind these patterns:
- Why Zig does things the way it does
- How to think idiomatically in Zig
- Which design decisions lead to better code

Every pattern embodies one or more Zen principles.

## Organization

Patterns are organized by problem domain:

- **memory/** - Memory management, allocation, and cleanup patterns
- **errors/** - Error handling, propagation, and recovery patterns
- **iterators/** - Iteration, parsing, and data processing patterns
- **io/** - Input/output, buffering, and streaming patterns
- **comptime/** - Compile-time programming and metaprogramming patterns
- **testing/** - Testing strategies and patterns

## Pattern Format

Each pattern document follows this structure:

1. **Problem**: What problem does this solve?
2. **When to use**: Scenarios where this pattern applies
3. **Alternatives**: Other approaches and trade-offs
4. **Basic Example**: Minimal focused code
5. **Real-World Example**: Complete practical usage
6. **Common Mistakes**: Anti-patterns to avoid
7. **See Also**: Related patterns and documentation

## For LLMs

These patterns are optimized for keyword search and problem-oriented queries like:
- "zig error handling"
- "zig defer cleanup"
- "zig custom iterator"
- "zig arena allocator"

Each pattern includes working code examples compatible with Zig 0.16.
