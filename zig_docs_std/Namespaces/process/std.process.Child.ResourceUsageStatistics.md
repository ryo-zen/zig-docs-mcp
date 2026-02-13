# std.process.Child.ResourceUsageStatistics

### Fields

    rusage: @TypeOf(rusage_init) = rusage_init

## Functions

`pub inline fn getMaxRss(rus: ResourceUsageStatistics) ?usize`
Returns the peak resident set size of the child process, in bytes, if available.
