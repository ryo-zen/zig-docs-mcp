# std.meta

## Overview

`std.meta` provides compile-time reflection helpers built on Zig type information.

Source: `/path/to/zig-0.16.0/lib/std/meta.zig`

## Public API

### Types and Imports

- `std.meta.TrailerFlags` - imported from `meta/trailer_flags.zig`.

### Enum and Declaration Helpers

- `std.meta.stringToEnum(T, str)` - converts a string to an enum value when it matches a tag name.
- `std.meta.declarations(T)` - returns declarations for a container type.
- `std.meta.declarationInfo(T, decl_name)` - returns declaration information for a named declaration.
- `std.meta.DeclEnum(T)` - creates an enum of declaration names.

### Type Shape Helpers

- `std.meta.alignment(T)` - alignment for a type.
- `std.meta.Child(T)` - child type for pointer, array, vector, or optional-like containers supported by the implementation.
- `std.meta.Elem(T)` - element type for indexable/container types supported by the implementation.
- `std.meta.Sentinel(T, sentinel_val)` - sentinel type helper.
- `std.meta.containerLayout(T)` - container layout for structs, unions, enums, and opaques.
- `std.meta.Tag(T)` - tag type for a union.
- `std.meta.activeTag(u)` - active union tag.

### Field Helpers

- `std.meta.fieldInfo(T, field)` - field information for a field enum value.
- `std.meta.fieldNames(T)` - compile-time array of field names.
- `std.meta.tags(T)` - compile-time array of enum tags or union tags.
- `std.meta.FieldEnum(T)` - creates an enum of field names.
- `std.meta.fieldIndex(T, name)` - returns a field index by name.

### Type Constructors and Comparisons

- `std.meta.eql(a, b)` - recursively compares values of the same type where supported.
- `std.meta.Int(signedness, bit_count)` - constructs an integer type.
- `std.meta.Float(bit_count)` - constructs a float type.
- `std.meta.ArgsTuple(Function)` - tuple type matching a function's parameters.
- `std.meta.Tuple(types)` - tuple type from a compile-time slice of types.
- `std.meta.isError(error_union)` - returns whether an error union currently contains an error.

## Notes

`std.meta` functions are primarily compile-time utilities. Many of them expect `comptime` type arguments and will emit compile errors when used with unsupported type shapes.
