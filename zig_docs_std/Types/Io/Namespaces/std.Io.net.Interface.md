# std.Io.net.Interface

### Fields

    index: u32

Value 0 indicates `none`.

## Types

- Name

## Values

|      |             |     |
|------|-------------|-----|
| none | `Interface` |     |

## Functions

`pub fn isNone(i: Interface) bool`  

`pub fn name(i: Interface, io: Io) NameError!Name`  
Asserts not `none`.

## Error Sets

- NameError
