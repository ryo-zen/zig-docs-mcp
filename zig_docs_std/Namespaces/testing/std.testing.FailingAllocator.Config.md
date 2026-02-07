# std.testing.FailingAllocator.Config

### Fields

    fail_index: usize = std.math.maxInt(usize)

The number of successful allocations you can expect from this allocator. The next allocation will fail.

    resize_fail_index: usize = std.math.maxInt(usize)

Number of successful resizes to expect from this allocator. The next resize will fail.
