# std.log.ScopeLevel

## Overview

`std.log.ScopeLevel` associates a specific logging scope with its minimum enabled `Level`.

It is used in logging configuration tables to override thresholds per scope.

### Fields

    scope: @EnumLiteral()

Scope identifier (for example `.http`, `.db`, `.default`).

    level: Level

Minimum enabled level for that scope.

## Usage Notes

- Use together with std options that accept per-scope level configuration.
- Scope names should match those used with `std.log.scoped(...)`.
