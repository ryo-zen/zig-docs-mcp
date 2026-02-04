# std.mem.Alignment

Stored as a power-of-two.

### Fields

    @"1" = 0

    @"2" = 1

    @"4" = 2

    @"8" = 3

    @"16" = 4

    @"32" = 5

    @"64" = 6

    _

## Functions

`pub fn backward(a: Alignment, address: usize) usize`  
Return previous address with this alignment.

`pub fn check(a: Alignment, address: usize) bool`  
Return whether address is aligned to this amount.

`pub fn compare(lhs: Alignment, op: std.math.CompareOperator, rhs: Alignment) bool`  

`pub fn forward(a: Alignment, address: usize) usize`  
Return next address with this alignment.

`pub fn fromByteUnits(n: usize) Alignment`  

`pub fn max(lhs: Alignment, rhs: Alignment) Alignment`  

`pub fn min(lhs: Alignment, rhs: Alignment) Alignment`  

`pub inline fn of(comptime T: type) Alignment`  

`pub fn order(lhs: Alignment, rhs: Alignment) std.math.Order`  

`pub fn toByteUnits(a: Alignment) usize`  
