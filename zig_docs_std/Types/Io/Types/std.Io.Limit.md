# std.Io.Limit

### Fields

    nothing = 0

    unlimited = std.math.maxInt(usize)

    _

## Functions

`pub fn countVec(data: []const []const u8) Limit`  

`pub fn limited(n: usize) Limit`  
`std.math.maxInt(usize)` is interpreted to mean `.unlimited`.

`pub fn limited64(n: u64) Limit`  
Any value grater than `std.math.maxInt(usize)` is interpreted to mean `.unlimited`.

`pub fn min(a: Limit, b: Limit) Limit`  

`pub fn minInt(l: Limit, n: usize) usize`  

`pub fn minInt64(l: Limit, n: u64) usize`  

`pub fn nonzero(l: Limit) bool`  

`pub fn slice(l: Limit, s: []u8) []u8`  

`pub fn slice1(l: Limit, non_empty_buffer: []u8) []u8`  
Reduces a slice to account for the limit, leaving room for one extra byte above the limit, allowing for the use case of differentiating between end-of-stream and reaching the limit.

`pub fn sliceConst(l: Limit, s: []const u8) []const u8`  

`pub fn subtract(l: Limit, amount: usize) ?Limit`  
Return a new limit reduced by `amount` or return `null` indicating limit would be exceeded.

`pub fn toInt(l: Limit) ?usize`  
