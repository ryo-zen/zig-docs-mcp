# std.testing.FailingAllocator

Allocator that fails after N allocations, useful for making sure out of memory conditions are handled correctly.

### Fields

    alloc_index: usize

    resize_index: usize

    internal_allocator: mem.Allocator

    allocated_bytes: usize

    freed_bytes: usize

    allocations: usize

    deallocations: usize

    stack_addresses: [num_stack_frames]usize

    has_induced_failure: bool

    fail_index: usize

    resize_fail_index: usize

## Types

- Config

## Functions

`pub fn allocator(self: *FailingAllocator) mem.Allocator`  

`pub fn getStackTrace(self: *FailingAllocator) std.builtin.StackTrace`  
Only valid once `has_induced_failure == true`

`pub fn init(internal_allocator: mem.Allocator, config: Config) FailingAllocator`  
