# std.mem

## Types

- Alignment
- Allocator
- DelimiterType
- SplitBackwardsIterator
- SplitIterator
- TokenIterator
- ValidationAllocator
- WindowIterator
- findMinMax
- indexOfMinMax
- minMax

## Values

|  |  |  |
|----|----|----|
| byte_size_in_bits |  | The standard library currently thoroughly depends on byte size being 8 bits. (see the use of u8 throughout allocation code as the "byte" type.) Code which depends on this can reference this declaration. If we ever try to port the standard library to a non-8-bit-byte platform, this will allow us to search for things which need to be updated. |
| readPackedIntForeign |  | Deprecated: use readPackedInt(T, bytes, bit_offset, value, .foreign) |
| readPackedIntNative |  | Deprecated: use readPackedInt(T, bytes, bit_offset, value, .native) |
| writePackedIntForeign |  | Deprecated: use writePackedInt(T, bytes, bit_offset, value, .foreign) |
| writePackedIntNative |  | Deprecated: use writePackedInt(T, bytes, bit_offset, value, .native) |

## Functions

`pub fn alignBackward(comptime T: type, addr: T, alignment: T) T`  
Round an address down to the previous (or current) aligned address. The alignment must be a power of 2 and greater than 0.

`pub fn alignBackwardAnyAlign(comptime T: type, addr: T, alignment: T) T`  
Round an address down to the previous (or current) aligned address. Unlike `alignBackward`, `alignment` can be any positive number, not just a power of 2.

`pub fn alignForward(comptime T: type, addr: T, alignment: T) T`  
Round an address up to the next (or current) aligned address. The alignment must be a power of 2 and greater than 0. Asserts that rounding up the address does not cause integer overflow.

`pub fn alignForwardAnyAlign(comptime T: type, addr: T, alignment: T) T`  
Round an address down to the next (or current) aligned address. Unlike `alignForward`, `alignment` can be any positive number, not just a power of 2.

`pub fn alignForwardLog2(addr: usize, log2_alignment: u8) usize`  
Rounds an address up to the next alignment boundary using log2 representation. Equivalent to alignForward with alignment = 1 \<\< log2_alignment. More efficient when alignment is known to be a power of 2.

`pub fn alignInBytes(bytes: []u8, comptime new_alignment: usize) ?[]align(new_alignment) u8`  
Returns the largest slice in the given bytes that conforms to the new alignment, or `null` if the given bytes contain no conforming address.

`pub fn alignInSlice(slice: anytype, comptime new_alignment: usize) ?AlignedSlice(@TypeOf(slice), new_alignment)`  
Returns the largest sub-slice within the given slice that conforms to the new alignment, or `null` if the given slice contains no conforming address.

`pub fn alignPointer(ptr: anytype, align_to: usize) ?@TypeOf(ptr)`  
Aligns a given pointer value to a specified alignment factor. Returns an aligned pointer or null if one of the following conditions is met:

- The aligned pointer would not fit the address space,
- The delta required to align the pointer is not a multiple of the pointee's type.

`pub fn alignPointerOffset(ptr: anytype, align_to: usize) ?usize`  
Returns the number of elements that, if added to the given pointer, align it to a multiple of the given quantity, or `null` if one of the following conditions is met:

- The aligned pointer would not fit the address space,
- The delta required to align the pointer is not a multiple of the pointee's type.

`pub fn allEqual(comptime T: type, slice: []const T, scalar: T) bool`  
Returns true if all elements in a slice are equal to the scalar value provided

`pub fn asBytes(ptr: anytype) AsBytesReturnType(@TypeOf(ptr))`  
Given a pointer to a single item, returns a slice of the underlying bytes, preserving pointer attributes.

`pub fn bigToNative(comptime T: type, x: T) T`  
Converts a big-endian integer to host endianness.

`pub fn boundedOrderZ(comptime T: type, lhs: [*:0]const T, rhs: [*:0]const T, bound: usize) math.Order`  
Compares two many-item pointers with NUL-termination lexicographically until some specified bound.

`pub fn byteSwapAllElements(comptime Elem: type, slice: []Elem) void`  
Reverses the byte order of all elements in a slice. Handles structs, unions, arrays, enums, floats, and integers recursively. Useful for converting between little-endian and big-endian representations.

`pub fn byteSwapAllFields(comptime S: type, ptr: *S) void`  
Swap the byte order of all the members of the fields of a struct (Changing their endianness)

`pub fn byteSwapAllFieldsAligned(comptime S: type, comptime a: Alignment, ptr: *align(a.toByteUnits()) S) void`  
Swap the byte order of all the members of the fields of a struct (Changing their endianness)

`pub fn bytesAsSlice(comptime T: type, bytes: anytype) BytesAsSliceReturnType(T, @TypeOf(bytes))`  
Given a slice of bytes, returns a slice of the specified type backed by those bytes, preserving pointer attributes. If `T` is zero-bytes sized, the returned slice has a len of zero.

`pub fn bytesAsValue(comptime T: type, bytes: anytype) BytesAsValueReturnType(T, @TypeOf(bytes))`  
Given a pointer to an array of bytes, returns a pointer to a value of the specified type backed by those bytes, preserving pointer attributes.

`pub fn bytesToValue(comptime T: type, bytes: anytype) T`  
Given a pointer to an array of bytes, returns a value of the specified type backed by a copy of those bytes.

`pub fn collapseRepeats(comptime T: type, slice: []T, elem: T) []T`  
Collapse consecutive duplicate elements into one entry.

`pub fn collapseRepeatsLen(comptime T: type, slice: []T, elem: T) usize`  
Collapse consecutive duplicate elements into one entry.

`pub fn concat(allocator: Allocator, comptime T: type, slices: []const []const T) Allocator.Error![]T`  
Copies each T from slices into a new slice that exactly holds all the elements.

`pub fn concatMaybeSentinel(allocator: Allocator, comptime T: type, slices: []const []const T, comptime s: ?T) Allocator.Error![]T`  
Copies each T from slices into a new slice that exactly holds all the elements as well as the sentinel.

`pub fn concatWithSentinel(allocator: Allocator, comptime T: type, slices: []const []const T, comptime s: T) Allocator.Error![:s]T`  
Copies each T from slices into a new slice that exactly holds all the elements.

`pub fn containsAtLeast(comptime T: type, haystack: []const T, expected_count: usize, needle: []const T) bool`  
Returns true if the haystack contains expected_count or more needles needle.len must be \> 0 does not count overlapping needles See also: `containsAtLeastScalar`

`pub fn containsAtLeastScalar(comptime T: type, list: []const T, minimum: usize, element: T) bool`  
Deprecated in favor of `containsAtLeastScalar2`.

`pub fn containsAtLeastScalar2(comptime T: type, list: []const T, element: T, minimum: usize) bool`  
Returns true if `element` appears at least `minimum` number of times in `list`. Related:

- `containsAtLeast`
- `countScalar`

`pub fn copyBackwards(comptime T: type, dest: []T, source: []const T) void`  
Copy all of source into dest at position 0. dest.len must be \>= source.len. If the slices overlap, dest.ptr must be \>= src.ptr. This function is deprecated; use @memmove instead.

`pub fn copyForwards(comptime T: type, dest: []T, source: []const T) void`  
Copy all of source into dest at position 0. dest.len must be \>= source.len. If the slices overlap, dest.ptr must be \<= src.ptr. This function is deprecated; use @memmove instead.

`pub fn count(comptime T: type, haystack: []const T, needle: []const T) usize`  
Returns the number of needles inside the haystack needle.len must be \> 0 does not count overlapping needles

`pub fn countScalar(comptime T: type, list: []const T, element: T) usize`  
Returns the number of times `element` appears in a slice of memory.

`pub fn cut(comptime T: type, haystack: []const T, needle: []const T) ?struct { []const T, []const T }`  
Returns slice of `haystack` before and after first occurrence of `needle`, or `null` if not found.

`pub fn cutLast(comptime T: type, haystack: []const T, needle: []const T) ?struct { []const T, []const T }`  
Returns slice of `haystack` before and after last occurrence of `needle`, or `null` if not found.

`pub fn cutPrefix(comptime T: type, slice: []const T, prefix: []const T) ?[]const T`  
If `slice` starts with `prefix`, returns the rest of `slice` starting at `prefix.len`.

`pub fn cutScalar(comptime T: type, haystack: []const T, needle: T) ?struct { []const T, []const T }`  
Returns slice of `haystack` before and after first occurrence `needle`, or `null` if not found.

`pub fn cutScalarLast(comptime T: type, haystack: []const T, needle: T) ?struct { []const T, []const T }`  
Returns slice of `haystack` before and after last occurrence of `needle`, or `null` if not found.

`pub fn cutSuffix(comptime T: type, slice: []const T, suffix: []const T) ?[]const T`  
If `slice` ends with `suffix`, returns `slice` from beginning to start of `suffix`.

`pub fn doNotOptimizeAway(val: anytype) void`  
Force an evaluation of the expression; this tries to prevent the compiler from optimizing the computation away even if the result eventually gets discarded.

`pub fn endsWith(comptime T: type, haystack: []const T, needle: []const T) bool`  
Returns true if haystack ends with needle. Time complexity: O(needle.len)

`pub fn eql(comptime T: type, a: []const T, b: []const T) bool`  
Returns true if and only if the slices have the same length and all elements compare true using equality operator.

`pub fn find(comptime T: type, haystack: []const T, needle: []const T) ?usize`  
Search for needle in haystack and return the index of the first occurrence. Uses Boyer-Moore-Horspool algorithm on large inputs; linear search on small inputs. Returns null if needle is not found.

`pub fn find(comptime T: type, haystack: []const T, needle: []const T) ?usize`  
Search for needle in haystack and return the index of the first occurrence. Uses Boyer-Moore-Horspool algorithm on large inputs; linear search on small inputs. Returns null if needle is not found.

`pub fn findAny(comptime T: type, slice: []const T, values: []const T) ?usize`  
Linear search for the index of any value in the provided list inside a slice. Returns null if no values are found.

`pub fn findAny(comptime T: type, slice: []const T, values: []const T) ?usize`  
Linear search for the index of any value in the provided list inside a slice. Returns null if no values are found.

`pub fn findAnyPos(comptime T: type, slice: []const T, start_index: usize, values: []const T) ?usize`  
Linear search for the index of any value in the provided list inside a slice, starting from a given position. Returns null if no values are found.

`pub fn findAnyPos(comptime T: type, slice: []const T, start_index: usize, values: []const T) ?usize`  
Linear search for the index of any value in the provided list inside a slice, starting from a given position. Returns null if no values are found.

`pub fn findDiff(comptime T: type, a: []const T, b: []const T) ?usize`  
Compares two slices and returns the index of the first inequality. Returns null if the slices are equal.

`pub fn findDiff(comptime T: type, a: []const T, b: []const T) ?usize`  
Compares two slices and returns the index of the first inequality. Returns null if the slices are equal.

`pub fn findLast(comptime T: type, haystack: []const T, needle: []const T) ?usize`  
Find the index in a slice of a sub-slice, searching from the end backwards. To start looking at a different index, slice the haystack first. Uses the Reverse Boyer-Moore-Horspool algorithm on large inputs; `lastIndexOfLinear` on small inputs.

`pub fn findLast(comptime T: type, haystack: []const T, needle: []const T) ?usize`  
Find the index in a slice of a sub-slice, searching from the end backwards. To start looking at a different index, slice the haystack first. Uses the Reverse Boyer-Moore-Horspool algorithm on large inputs; `lastIndexOfLinear` on small inputs.

`pub fn findLastAny(comptime T: type, slice: []const T, values: []const T) ?usize`  
Linear search for the last index of any value in the provided list inside a slice. Returns null if no values are found.

`pub fn findLastAny(comptime T: type, slice: []const T, values: []const T) ?usize`  
Linear search for the last index of any value in the provided list inside a slice. Returns null if no values are found.

`pub fn findLastLinear(comptime T: type, haystack: []const T, needle: []const T) ?usize`  
Find the index in a slice of a sub-slice, searching from the end backwards. To start looking at a different index, slice the haystack first. Consider using `lastIndexOf` instead of this, which will automatically use a more sophisticated algorithm on larger inputs.

`pub fn findLastLinear(comptime T: type, haystack: []const T, needle: []const T) ?usize`  
Find the index in a slice of a sub-slice, searching from the end backwards. To start looking at a different index, slice the haystack first. Consider using `lastIndexOf` instead of this, which will automatically use a more sophisticated algorithm on larger inputs.

`pub fn findLastNone(comptime T: type, slice: []const T, values: []const T) ?usize`  
Find the last item in `slice` which is not contained in `values`.

`pub fn findLastNone(comptime T: type, slice: []const T, values: []const T) ?usize`  
Find the last item in `slice` which is not contained in `values`.

`pub fn findMax(comptime T: type, slice: []const T) usize`  
Returns the index of the largest number in a slice. O(n). `slice` must not be empty.

`pub fn findMax(comptime T: type, slice: []const T) usize`  
Returns the index of the largest number in a slice. O(n). `slice` must not be empty.

`pub fn findMin(comptime T: type, slice: []const T) usize`  
Returns the index of the smallest number in a slice. O(n). `slice` must not be empty.

`pub fn findMin(comptime T: type, slice: []const T) usize`  
Returns the index of the smallest number in a slice. O(n). `slice` must not be empty.

`pub fn findNone(comptime T: type, slice: []const T, values: []const T) ?usize`  
Find the first item in `slice` which is not contained in `values`.

`pub fn findNone(comptime T: type, slice: []const T, values: []const T) ?usize`  
Find the first item in `slice` which is not contained in `values`.

`pub fn findNonePos(comptime T: type, slice: []const T, start_index: usize, values: []const T) ?usize`  
Find the first item in `slice[start_index..]` which is not contained in `values`. The returned index will be relative to the start of `slice`, and never less than `start_index`.

`pub fn findNonePos(comptime T: type, slice: []const T, start_index: usize, values: []const T) ?usize`  
Find the first item in `slice[start_index..]` which is not contained in `values`. The returned index will be relative to the start of `slice`, and never less than `start_index`.

`pub fn findPos(comptime T: type, haystack: []const T, start_index: usize, needle: []const T) ?usize`  
Uses Boyer-Moore-Horspool algorithm on large inputs; `findPosLinear` on small inputs.

`pub fn findPos(comptime T: type, haystack: []const T, start_index: usize, needle: []const T) ?usize`  
Uses Boyer-Moore-Horspool algorithm on large inputs; `findPosLinear` on small inputs.

`pub fn findPosLinear(comptime T: type, haystack: []const T, start_index: usize, needle: []const T) ?usize`  
Consider using `findPos` instead of this, which will automatically use a more sophisticated algorithm on larger inputs.

`pub fn findPosLinear(comptime T: type, haystack: []const T, start_index: usize, needle: []const T) ?usize`  
Consider using `findPos` instead of this, which will automatically use a more sophisticated algorithm on larger inputs.

`pub fn findScalar(comptime T: type, slice: []const T, value: T) ?usize`  
Linear search for the index of a scalar value inside a slice.

`pub fn findScalar(comptime T: type, slice: []const T, value: T) ?usize`  
Linear search for the index of a scalar value inside a slice.

`pub fn findScalarLast(comptime T: type, slice: []const T, value: T) ?usize`  
Linear search for the last index of a scalar value inside a slice.

`pub fn findScalarLast(comptime T: type, slice: []const T, value: T) ?usize`  
Linear search for the last index of a scalar value inside a slice.

`pub fn findScalarPos(comptime T: type, slice: []const T, start_index: usize, value: T) ?usize`  
Linear search for the index of a scalar value inside a slice, starting from a given position. Returns null if the value is not found.

`pub fn findScalarPos(comptime T: type, slice: []const T, start_index: usize, value: T) ?usize`  
Linear search for the index of a scalar value inside a slice, starting from a given position. Returns null if the value is not found.

`pub fn findSentinel(comptime T: type, comptime sentinel: T, p: [*:sentinel]const T) usize`  
Returns the index of the sentinel value in a sentinel-terminated pointer. Linear search through memory until the sentinel is found.

`pub fn findSentinel(comptime T: type, comptime sentinel: T, p: [*:sentinel]const T) usize`  
Returns the index of the sentinel value in a sentinel-terminated pointer. Linear search through memory until the sentinel is found.

`pub fn isAligned(addr: usize, alignment: usize) bool`  
Given an address and an alignment, return true if the address is a multiple of the alignment The alignment must be a power of 2 and greater than 0.

`pub fn isAlignedAnyAlign(i: usize, alignment: usize) bool`  
Returns true if i is aligned to the given alignment. Works with any positive alignment value, not just powers of 2. For power-of-2 alignments, `isAligned` is more efficient.

`pub fn isAlignedGeneric(comptime T: type, addr: T, alignment: T) bool`  
Generic version of `isAligned` that works with any integer type. Returns true if addr is aligned to the given alignment. Alignment must be a power of 2 and greater than 0.

`pub fn isAlignedLog2(addr: usize, log2_alignment: u8) bool`  
Returns true if addr is aligned to 2^log2_alignment. More efficient than `isAligned` when alignment is known to be a power of 2. log2_alignment must be \< @bitSizeOf(usize).

`pub fn isValidAlign(alignment: usize) bool`  
Returns whether `alignment` is a valid alignment, meaning it is a positive power of 2.

`pub fn isValidAlignGeneric(comptime T: type, alignment: T) bool`  
Returns whether `alignment` is a valid alignment, meaning it is a positive power of 2.

`pub fn join(allocator: Allocator, separator: []const u8, slices: []const []const u8) Allocator.Error![]u8`  
Naively combines a series of slices with a separator. Allocates memory for the result, which must be freed by the caller.

`pub fn joinZ(allocator: Allocator, separator: []const u8, slices: []const []const u8) Allocator.Error![:0]u8`  
Naively combines a series of slices with a separator and null terminator. Allocates memory for the result, which must be freed by the caller.

`pub fn len(value: anytype) usize`  
Takes a sentinel-terminated pointer and iterates over the memory to find the sentinel and determine the length. `[*c]` pointers are assumed to be non-null and 0-terminated.

`pub fn lessThan(comptime T: type, lhs: []const T, rhs: []const T) bool`  
Returns true if lhs \< rhs, false otherwise

`pub fn littleToNative(comptime T: type, x: T) T`  
Converts a little-endian integer to host endianness.

`pub fn max(comptime T: type, slice: []const T) T`  
Returns the largest number in a slice. O(n). `slice` must not be empty.

`pub fn min(comptime T: type, slice: []const T) T`  
Returns the smallest number in a slice. O(n). `slice` must not be empty.

`pub fn nativeTo(comptime T: type, x: T, desired_endianness: Endian) T`  
Converts an integer which has host endianness to the desired endianness.

`pub fn nativeToBig(comptime T: type, x: T) T`  
Converts an integer which has host endianness to big endian.

`pub fn nativeToLittle(comptime T: type, x: T) T`  
Converts an integer which has host endianness to little endian.

`pub fn order(comptime T: type, lhs: []const T, rhs: []const T) math.Order`  
Compares two slices of numbers lexicographically. O(n).

`pub fn orderZ(comptime T: type, lhs: [*:0]const T, rhs: [*:0]const T) math.Order`  
Compares two many-item pointers with NUL-termination lexicographically.

`pub inline fn readInt(comptime T: type, buffer: *const [@divExact(@typeInfo(T).int.bits, 8)]u8, endian: Endian) T`  
Reads an integer from memory with bit count specified by T. The bit count of T must be evenly divisible by 8. This function cannot fail and cannot cause undefined behavior.

`pub fn readPackedInt(comptime T: type, bytes: []const u8, bit_offset: usize, endian: Endian) T`  
Loads an integer from packed memory. Asserts that buffer contains at least bit_offset + @bitSizeOf(T) bits.

`pub fn readVarInt(comptime ReturnType: type, bytes: []const u8, endian: Endian) ReturnType`  
Reads an integer from memory with size equal to bytes.len. ReturnType specifies the return type, which must be large enough to store the result.

`pub fn readVarPackedInt( comptime T: type, bytes: []const u8, bit_offset: usize, bit_count: usize, endian: std.builtin.Endian, signedness: std.builtin.Signedness, ) T`  
Loads an integer from packed memory with provided bit_count, bit_offset, and signedness. Asserts that T is large enough to store the read value.

`pub fn replace(comptime T: type, input: []const T, needle: []const T, replacement: []const T, output: []T) usize`  
Replace needle with replacement as many times as possible, writing to an output buffer which is assumed to be of appropriate size. Use replacementSize to calculate an appropriate buffer size. The `input` and `output` slices must not overlap. The needle must not be empty. Returns the number of replacements made.

`pub fn replaceOwned(comptime T: type, allocator: Allocator, input: []const T, needle: []const T, replacement: []const T) Allocator.Error![]T`  
Perform a replacement on an allocated buffer of pre-determined size. Caller must free returned memory.

`pub fn replaceScalar(comptime T: type, slice: []T, match: T, replacement: T) void`  
Replace all occurrences of `match` with `replacement`.

`pub fn replacementSize(comptime T: type, input: []const T, needle: []const T, replacement: []const T) usize`  
Calculate the size needed in an output buffer to perform a replacement. The needle must not be empty.

`pub fn reverse(comptime T: type, items: []T) void`  
In-place order reversal of a slice

`pub fn reverseIterator(slice: anytype) ReverseIterator(@TypeOf(slice))`  
Iterates over a slice in reverse.

`pub fn rotate(comptime T: type, items: []T, amount: usize) void`  
In-place rotation of the values in an array (\[0 1 2 3\] becomes \[1 2 3 0\] if we rotate by 1) Assumes 0 \<= amount \<= items.len

`pub fn sliceAsBytes(slice: anytype) SliceAsBytesReturnType(@TypeOf(slice))`  
Given a slice, returns a slice of the underlying bytes, preserving pointer attributes.

`pub fn sliceTo(ptr: anytype, comptime end: std.meta.Elem(@TypeOf(ptr))) SliceTo(@TypeOf(ptr), end)`  
Takes a pointer to an array, a many-item pointer, or a slice, and returns a slice of the items up to the first occurrence of `end`. If `end` is not found, the resulting slice will include all items up to the input's length or sentinel. If the pointer type is unbounded (no length or sentinel), `end` will be the sentinel for the resulting slice. If the pointer type is sentinel-terminated by `end`, the resulting slice will also be sentinel-terminated by `end`. Pointer properties such as mutability and alignment are preserved. C pointers are assumed to be non-null.

`pub fn sort( comptime T: type, items: []T, context: anytype, comptime lessThanFn: fn (@TypeOf(context), lhs: T, rhs: T) bool, ) void`  
Sorts a slice in-place using a stable algorithm (maintains relative order of equal elements). Average time complexity: O(n log n), worst case: O(n log n) Space complexity: O(log n) for recursive calls

`pub fn sortContext(a: usize, b: usize, context: anytype) void`  
TODO: currently this just calls `insertionSortContext`. The block sort implementation in this file needs to be adapted to use the sort context.

`pub fn sortUnstable( comptime T: type, items: []T, context: anytype, comptime lessThanFn: fn (@TypeOf(context), lhs: T, rhs: T) bool, ) void`  
Sorts a slice in-place using an unstable algorithm (does not preserve relative order of equal elements). Time complexity: O(n) best case, O(n log n) worst case and average case. Generally faster than stable sort but order of equal elements is undefined.

`pub fn sortUnstableContext(a: usize, b: usize, context: anytype) void`  
Sorts a range \[a, b) using an unstable algorithm with custom context. This is a lower-level interface for sorting that works with indices instead of slices. Does not preserve relative order of equal elements.

`pub fn span(ptr: anytype) Span(@TypeOf(ptr))`  
Takes a sentinel-terminated pointer and returns a slice, iterating over the memory to find the sentinel and determine the length. Pointer attributes such as const are preserved. `[*c]` pointers are assumed to be non-null and 0-terminated.

`pub fn splitAny(comptime T: type, buffer: []const T, delimiters: []const T) SplitIterator(T, .any)`  
Returns an iterator that iterates over the slices of `buffer` that are separated by any item in `delimiters`.

`pub fn splitBackwardsAny(comptime T: type, buffer: []const T, delimiters: []const T) SplitBackwardsIterator(T, .any)`  
Returns an iterator that iterates backwards over the slices of `buffer` that are separated by any item in `delimiters`.

`pub fn splitBackwardsScalar(comptime T: type, buffer: []const T, delimiter: T) SplitBackwardsIterator(T, .scalar)`  
Returns an iterator that iterates backwards over the slices of `buffer` that are separated by `delimiter`.

`pub fn splitBackwardsSequence(comptime T: type, buffer: []const T, delimiter: []const T) SplitBackwardsIterator(T, .sequence)`  
Returns an iterator that iterates backwards over the slices of `buffer` that are separated by the sequence in `delimiter`.

`pub fn splitScalar(comptime T: type, buffer: []const T, delimiter: T) SplitIterator(T, .scalar)`  
Returns an iterator that iterates over the slices of `buffer` that are separated by `delimiter`.

`pub fn splitSequence(comptime T: type, buffer: []const T, delimiter: []const T) SplitIterator(T, .sequence)`  
Returns an iterator that iterates over the slices of `buffer` that are separated by the byte sequence in `delimiter`.

`pub fn startsWith(comptime T: type, haystack: []const T, needle: []const T) bool`  
Returns true if haystack starts with needle. Time complexity: O(needle.len)

`pub fn swap(comptime T: type, noalias a: *T, noalias b: *T) void`  
Exchanges contents of two memory locations.

`pub fn toBytes(value: anytype) [@sizeOf(@TypeOf(value))]u8`  
Given any value, returns a copy of its bytes in an array.

`pub fn toNative(comptime T: type, x: T, endianness_of_x: Endian) T`  
Converts an integer from specified endianness to host endianness.

`pub fn tokenizeAny(comptime T: type, buffer: []const T, delimiters: []const T) TokenIterator(T, .any)`  
Returns an iterator that iterates over the slices of `buffer` that are not any of the items in `delimiters`.

`pub fn tokenizeScalar(comptime T: type, buffer: []const T, delimiter: T) TokenIterator(T, .scalar)`  
Returns an iterator that iterates over the slices of `buffer` that are not `delimiter`.

`pub fn tokenizeSequence(comptime T: type, buffer: []const T, delimiter: []const T) TokenIterator(T, .sequence)`  
Returns an iterator that iterates over the slices of `buffer` that are not the sequence in `delimiter`.

`pub fn trim(comptime T: type, slice: []const T, values_to_strip: []const T) []const T`  
Remove a set of values from the beginning and end of a slice.

`pub fn trimEnd(comptime T: type, slice: []const T, values_to_strip: []const T) []const T`  
Remove a set of values from the end of a slice.

`pub fn trimStart(comptime T: type, slice: []const T, values_to_strip: []const T) []const T`  
Remove a set of values from the beginning of a slice.

`pub fn validationWrap(allocator: anytype) ValidationAllocator(@TypeOf(allocator))`  
Wraps an allocator with basic validation checks. Asserts that allocation sizes are greater than zero and returned pointers have correct alignment.

`pub fn window(comptime T: type, buffer: []const T, size: usize, advance: usize) WindowIterator(T)`  
Returns an iterator with a sliding window of slices for `buffer`. The sliding window has length `size` and on every iteration moves forward by `advance`.

`pub inline fn writeInt(comptime T: type, buffer: *[@divExact(@typeInfo(T).int.bits, 8)]u8, value: T, endian: Endian) void`  
Writes an integer to memory, storing it in twos-complement. This function always succeeds, has defined behavior for all inputs, but the integer bit width must be divisible by 8.

`pub fn writePackedInt(comptime T: type, bytes: []u8, bit_offset: usize, value: T, endian: Endian) void`  
Stores an integer to packed memory. Asserts that buffer contains at least bit_offset + @bitSizeOf(T) bits.

`pub fn writeVarPackedInt(bytes: []u8, bit_offset: usize, bit_count: usize, value: anytype, endian: std.builtin.Endian) void`  
Stores an integer to packed memory with provided bit_offset, bit_count, and signedness. If negative, the written value is sign-extended.

`pub fn zeroInit(comptime T: type, init: anytype) T`  
Initializes all fields of the struct with their default value, or zero values if no default value is present. If the field is present in the provided initial values, it will have that value instead. Structs are initialized recursively.

`pub fn zeroes(comptime T: type) T`  
Generally, Zig users are encouraged to explicitly initialize all fields of a struct explicitly rather than using this function. However, it is recognized that there are sometimes use cases for initializing all fields to a "zero" value. For example, when interfacing with a C API where this practice is more common and relied upon. If you are performing code review and see this function used, examine closely - it may be a code smell. Zero initializes the type. This can be used to zero-initialize any type for which it makes sense. Structs will be initialized recursively.
