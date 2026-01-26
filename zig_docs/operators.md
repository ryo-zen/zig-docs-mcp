# Operators §

There is no operator overloading. When you see an operator in Zig, you know that it is doing something from this table, and nothing else. 

### Table of Operators §

Name | Syntax | Types | Remarks | Example  
---|---|---|---|---  
Addition | 

    ```
    a + b
    a += b
    ```

| 

  * Integers
  * Floats

| 

  * Can cause overflow for integers.
  * Invokes Peer Type Resolution for the operands.
  * See also @addWithOverflow.

| 

    ```
    2 + 5 == 7
    ```  
  
Wrapping Addition | 

    ```
    a +% b
    a +%= b
    ```

| 

  * Integers

| 

  * Twos-complement wrapping behavior.
  * Invokes Peer Type Resolution for the operands.
  * See also @addWithOverflow.

| 

    ```
    @as(u32, 0xffffffff) +% 1 == 0
    ```  
  
Saturating Addition | 

    ```
    a +| b
    a +|= b
    ```

| 

  * Integers

| 

  * Invokes Peer Type Resolution for the operands.

| 

    ```
    @as(u8, 255) +| 1 == @as(u8, 255)
    ```  
  
Subtraction | 

    ```
    a - b
    a -= b
    ```

| 

  * Integers
  * Floats

| 

  * Can cause overflow for integers.
  * Invokes Peer Type Resolution for the operands.
  * See also @subWithOverflow.

| 

    ```
    2 - 5 == -3
    ```  
  
Wrapping Subtraction | 

    ```
    a -% b
    a -%= b
    ```

| 

  * Integers

| 

  * Twos-complement wrapping behavior.
  * Invokes Peer Type Resolution for the operands.
  * See also @subWithOverflow.

| 

    ```
    @as(u8, 0) -% 1 == 255
    ```  
  
Saturating Subtraction | 

    ```
    a -| b
    a -|= b
    ```

| 

  * Integers

| 

  * Invokes Peer Type Resolution for the operands.

| 

    ```
    @as(u32, 0) -| 1 == 0
    ```  
  
Negation | 

    ```
    -a
    ```

| 

  * Integers
  * Floats

| 

  * Can cause overflow for integers.

| 

    ```
    -1 == 0 - 1
    ```  
  
Wrapping Negation | 

    ```
    -%a
    ```

| 

  * Integers

| 

  * Twos-complement wrapping behavior.

| 

    ```
    -%@as(i8, -128) == -128
    ```  
  
Multiplication | 

    ```
    a * b
    a *= b
    ```

| 

  * Integers
  * Floats

| 

  * Can cause overflow for integers.
  * Invokes Peer Type Resolution for the operands.
  * See also @mulWithOverflow.

| 

    ```
    2 * 5 == 10
    ```  
  
Wrapping Multiplication | 

    ```
    a *% b
    a *%= b
    ```

| 

  * Integers

| 

  * Twos-complement wrapping behavior.
  * Invokes Peer Type Resolution for the operands.
  * See also @mulWithOverflow.

| 

    ```
    @as(u8, 200) *% 2 == 144
    ```  
  
Saturating Multiplication | 

    ```
    a *| b
    a *|= b
    ```

| 

  * Integers

| 

  * Invokes Peer Type Resolution for the operands.

| 

    ```
    @as(u8, 200) *| 2 == 255
    ```  
  
Division | 

    ```
    a / b
    a /= b
    ```

| 

  * Integers
  * Floats

| 

  * Can cause overflow for integers.
  * Can cause Division by Zero for integers.
  * Can cause Division by Zero for floats in FloatMode.Optimized Mode.
  * Signed integer operands must be comptime-known and positive. In other cases, use @divTrunc, @divFloor, or @divExact instead. 
  * Invokes Peer Type Resolution for the operands.

| 

    ```
    10 / 5 == 2
    ```  
  
Remainder Division | 

    ```
    a % b
    a %= b
    ```

| 

  * Integers
  * Floats

| 

  * Can cause Division by Zero for integers.
  * Can cause Division by Zero for floats in FloatMode.Optimized Mode.
  * Signed or floating-point operands must be comptime-known and positive. In other cases, use @rem or @mod instead. 
  * Invokes Peer Type Resolution for the operands.

| 

    ```
    10 % 3 == 1
    ```  
  
Bit Shift Left | 

    ```
    a << b
    a <<= b
    ```

| 

  * Integers

| 

  * Moves all bits to the left, inserting new zeroes at the least-significant bit.
  * `b` must be comptime-known or have a type with log2 number of bits as `a`.
  * See also @shlExact.
  * See also @shlWithOverflow.

| 

    ```
    0b1 << 8 == 0b100000000
    ```  
  
Saturating Bit Shift Left | 

    ```
    a <<| b
    a <<|= b
    ```

| 

  * Integers

| 

  * See also @shlExact.
  * See also @shlWithOverflow.

| 

    ```
    @as(u8, 1) <<| 8 == 255
    ```  
  
Bit Shift Right | 

    ```
    a >> b
    a >>= b
    ```

| 

  * Integers

| 

  * Moves all bits to the right, inserting zeroes at the most-significant bit.
  * `b` must be comptime-known or have a type with log2 number of bits as `a`.
  * See also @shrExact.

| 

    ```
    0b1010 >> 1 == 0b101
    ```  
  
Bitwise And | 

    ```
    a & b
    a &= b
    ```

| 

  * Integers

| 

  * Invokes Peer Type Resolution for the operands.

| 

    ```
    0b011 & 0b101 == 0b001
    ```  
  
Bitwise Or | 

    ```
    a | b
    a |= b
    ```

| 

  * Integers

| 

  * Invokes Peer Type Resolution for the operands.

| 

    ```
    0b010 | 0b100 == 0b110
    ```  
  
Bitwise Xor | 

    ```
    a ^ b
    a ^= b
    ```

| 

  * Integers

| 

  * Invokes Peer Type Resolution for the operands.

| 

    ```
    0b011 ^ 0b101 == 0b110
    ```  
  
Bitwise Not | 

    ```
    ~a
    ```

| 

  * Integers

|  | 

    ```
    ~@as(u8, 0b10101111) == 0b01010000
    ```  
  
Defaulting Optional Unwrap | 

    ```
    a orelse b
    ```

| 

  * Optionals

| If `a` is `null`, returns `b` ("default value"), otherwise returns the unwrapped value of `a`. Note that `b` may be a value of type noreturn.  | 

    ```zig
    const value: ?u32 = null;
    const unwrapped = value orelse 1234;
    unwrapped == 1234
    ```  
  
Optional Unwrap | 

    ```
    a.?
    ```

| 

  * Optionals

|  Equivalent to: 

    ```
    a orelse unreachable
    ```

| 

    ```zig
    const value: ?u32 = 5678;
    value.? == 5678
    ```  
  
Defaulting Error Unwrap | 

    ```
    a catch b
    a catch |err| b
    ```

| 

  * Error Unions

| If `a` is an `error`, returns `b` ("default value"), otherwise returns the unwrapped value of `a`. Note that `b` may be a value of type noreturn. `err` is the `error` and is in scope of the expression `b`.  | 

    ```zig
    const value: anyerror!u32 = error.Broken;
    const unwrapped = value catch 1234;
    unwrapped == 1234
    ```  
  
Logical And | 

    ```
    a and b
    ```

| 

  * bool

|  If `a` is `false`, returns `false` without evaluating `b`. Otherwise, returns `b`.  | 

    ```
    (false and true) == false
    ```  
  
Logical Or | 

    ```
    a or b
    ```

| 

  * bool

|  If `a` is `true`, returns `true` without evaluating `b`. Otherwise, returns `b`.  | 

    ```
    (false or true) == true
    ```  
  
Boolean Not | 

    ```
    !a
    ```

| 

  * bool

|  | 

    ```
    !false == true
    ```  
  
Equality | 

    ```
    a == b
    ```

| 

  * Integers
  * Floats
  * bool
  * type

|  Returns `true` if a and b are equal, otherwise returns `false`. Invokes Peer Type Resolution for the operands.  | 

    ```
    (1 == 1) == true
    ```  
  
Null Check | 

    ```
    a == null
    ```

| 

  * Optionals

|  Returns `true` if a is `null`, otherwise returns `false`.  | 

    ```zig
    const value: ?u32 = null;
    (value == null) == true
    ```  
  
Inequality | 

    ```
    a != b
    ```

| 

  * Integers
  * Floats
  * bool
  * type

|  Returns `false` if a and b are equal, otherwise returns `true`. Invokes Peer Type Resolution for the operands.  | 

    ```
    (1 != 1) == false
    ```  
  
Non-Null Check | 

    ```
    a != null
    ```

| 

  * Optionals

|  Returns `false` if a is `null`, otherwise returns `true`.  | 

    ```zig
    const value: ?u32 = null;
    (value != null) == false
    ```  
  
Greater Than | 

    ```
    a > b
    ```

| 

  * Integers
  * Floats

|  Returns `true` if a is greater than b, otherwise returns `false`. Invokes Peer Type Resolution for the operands.  | 

    ```
    (2 > 1) == true
    ```  
  
Greater or Equal | 

    ```
    a >= b
    ```

| 

  * Integers
  * Floats

|  Returns `true` if a is greater than or equal to b, otherwise returns `false`. Invokes Peer Type Resolution for the operands.  | 

    ```
    (2 >= 1) == true
    ```  
  
Less Than | 

    ```
    a < b
    ```

| 

  * Integers
  * Floats

|  Returns `true` if a is less than b, otherwise returns `false`. Invokes Peer Type Resolution for the operands.  | 

    ```
    (1 < 2) == true
    ```  
  
Lesser or Equal | 

    ```
    a <= b
    ```

| 

  * Integers
  * Floats

|  Returns `true` if a is less than or equal to b, otherwise returns `false`. Invokes Peer Type Resolution for the operands.  | 

    ```
    (1 <= 2) == true
    ```  
  
Array Concatenation | 

    ```
    a ++ b
    ```

| 

  * Arrays

| 

  * Only available when the lengths of both `a` and `b` are compile-time known.

| 

    ```zig
    const mem = @import("std").mem;
    const array1 = [_]u32{1,2};
    const array2 = [_]u32{3,4};
    const together = array1 ++ array2;
    mem.eql(u32, &together, &[_]u32{1,2,3,4})
    ```  
  
Array Multiplication | 

    ```
    a ** b
    ```

| 

  * Arrays

| 

  * Only available when the length of `a` and `b` are compile-time known.

| 

    ```zig
    const mem = @import("std").mem;
    const pattern = "ab" ** 3;
    mem.eql(u8, pattern, "ababab")
    ```  
  
Pointer Dereference | 

    ```
    a.*
    ```

| 

  * Pointers

|  Pointer dereference.  | 

    ```zig
    const x: u32 = 1234;
    const ptr = &x;
    ptr.* == 1234
    ```  
  
Address Of | 

    ```
    &a
    ```

|  All types  |  | 

    ```zig
    const x: u32 = 1234;
    const ptr = &x;
    ptr.* == 1234
    ```  
  
Error Set Merge | 

    ```
    a || b
    ```

| 

  * Error Set Type

|  Merging Error Sets | 

    ```zig
    const A = error{One};
    const B = error{Two};
    (A || B) == error{One, Two}
    ```  
  
### Precedence §

    ```
    x() x[] x.y x.* x.?
    a!b
    x{}
    !x -x -%x ~x &x ?x
    * / % ** *% *| ||
    + - ++ +% -% +| -|
    << >> <<|
    & ^ | orelse catch
    == != < > <= >=
    and
    or
    = *= *%= *|= /= %= += +%= +|= -= -%= -|= <<= <<|= >>= &= ^= |=
    ```