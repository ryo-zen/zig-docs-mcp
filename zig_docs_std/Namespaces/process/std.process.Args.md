# std.process.Args

### Fields

    vector: Vector

## Types

- Iterator
- IteratorGeneral
- IteratorGeneralOptions
- Vector

## Functions

`pub fn iterate(a: Args) Iterator`  
Holds the command-line arguments, with the program name as the first entry. Use `iterateAllocator` for cross-platform code.

`pub fn iterateAllocator(a: Args, gpa: Allocator) Iterator.InitError!Iterator`  
You must deinitialize iterator's internal buffers by calling `deinit` when done.

`pub fn toSlice(a: Args, arena: Allocator) ToSliceError![]const [:0]const u8`  
Returned value may reference several allocations and may point into `a`. Thefore, an arena-style allocator must be used.

## Error Sets

- ToSliceError
