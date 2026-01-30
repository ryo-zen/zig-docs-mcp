# Operators

There is no operator overloading. When you see an operator in Zig, you know that
      it is doing something from this table, and nothing else.
      

      
## [Table of Operators](#toc-Table-of-Operators) §

      
      
        
        
          Name
          Syntax
          Types
          Remarks
          Example
        
        
        
        
          Addition
          
```zig
a + b
a += b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
            
              
- Can cause [overflow](#Default-Operations) for integers.
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
              
- See also [@addWithOverflow](#addWithOverflow).
            
          
          
            
```zig
2 + 5 == 7
```

          
        
        
          Wrapping Addition
          
```zig
a +% b
a +%= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Twos-complement wrapping behavior.
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
              
- See also [@addWithOverflow](#addWithOverflow).
            
          
          
            
```zig
@as(u32, 0xffffffff) +% 1 == 0
```

          
        
        
          Saturating Addition
          
```zig
a +| b
a +|= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
@as(u8, 255) +| 1 == @as(u8, 255)
```

          
        
        
          Subtraction
          
```zig
a - b
a -= b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
            
              
- Can cause [overflow](#Default-Operations) for integers.
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
              
- See also [@subWithOverflow](#subWithOverflow).
            
          
          
            
```zig
2 - 5 == -3
```

          
        
        
          Wrapping Subtraction
          
```zig
a -% b
a -%= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Twos-complement wrapping behavior.
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
              
- See also [@subWithOverflow](#subWithOverflow).
            
          
          
            
```zig
@as(u8, 0) -% 1 == 255
```

          
        
        
          Saturating Subtraction
          
```zig
a -| b
a -|= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
@as(u32, 0) -| 1 == 0
```

          
        
        
          Negation
          
```zig
-a
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
            
              
- Can cause [overflow](#Default-Operations) for integers.
            
          
          
            
```zig
-1 == 0 - 1
```

          
        
        
          Wrapping Negation
          
```zig
-%a
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Twos-complement wrapping behavior.
            
          
          
            
```zig
-%@as(i8, -128) == -128
```

          
        
        
          Multiplication
          
```zig
a * b
a *= b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
            
              
- Can cause [overflow](#Default-Operations) for integers.
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
              
- See also [@mulWithOverflow](#mulWithOverflow).
            
          
          
            
```zig
2 * 5 == 10
```

          
        
        
          Wrapping Multiplication
          
```zig
a *% b
a *%= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Twos-complement wrapping behavior.
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
              
- See also [@mulWithOverflow](#mulWithOverflow).
            
          
          
            
```zig
@as(u8, 200) *% 2 == 144
```

          
        
        
          Saturating Multiplication
          
```zig
a *| b
a *|= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
@as(u8, 200) *| 2 == 255
```

          
        
        
          Division
          
```zig
a / b
a /= b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
            
              
- Can cause [overflow](#Default-Operations) for integers.
              
- Can cause [Division by Zero](#Division-by-Zero) for integers.
              
- Can cause [Division by Zero](#Division-by-Zero) for floats in [FloatMode.Optimized Mode](#Floating-Point-Operations).
              Signed integer operands must be comptime-known and positive. In other cases, use
                [@divTrunc](#divTrunc),
                [@divFloor](#divFloor), or
                [@divExact](#divExact) instead.
              
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
10 / 5 == 2
```

          
        
        
          Remainder Division
          
```zig
a % b
a %= b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
            
              
- Can cause [Division by Zero](#Division-by-Zero) for integers.
              
- Can cause [Division by Zero](#Division-by-Zero) for floats in [FloatMode.Optimized Mode](#Floating-Point-Operations).
              Signed or floating-point operands must be comptime-known and positive. In other cases, use
                [@rem](#rem) or
                [@mod](#mod) instead.
              
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
10 % 3 == 1
```

          
        
        
          Bit Shift Left
          
```zig
a 
          
            
              
- [Integers](#Integers)
            
          
          
            
              Moves all bits to the left, inserting new zeroes at the
              least-significant bit.
              `b` must be
              [comptime-known](#comptime) or have a type with log2 number
              of bits as `a`.
              
- See also [@shlExact](#shlExact).
              
- See also [@shlWithOverflow](#shlWithOverflow).
            
          
          
            
```zig
0b1 8 == 0b100000000
```

          
        
        
          Saturating Bit Shift Left
          
```zig
a 
          
            
              
- [Integers](#Integers)
            
          
          
            
              
- See also [@shlExact](#shlExact).
              
- See also [@shlWithOverflow](#shlWithOverflow).
            
          
          
            
```zig
@as(u8, 1) 8 == 255
```

          
        
        
          Bit Shift Right
          
```zig
a >> b
a >>= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Moves all bits to the right, inserting zeroes at the most-significant bit.
              `b` must be
                [comptime-known](#comptime) or have a type with log2 number
                of bits as `a`.
              
- See also [@shrExact](#shrExact).
            
          
          
            
```zig
0b1010 >> 1 == 0b101
```

          
        
        
          Bitwise And
          
```zig
a & b
a &= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
0b011 & 0b101 == 0b001
```

          
        
        
          Bitwise Or
          
```zig
a | b
a |= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
0b010 | 0b100 == 0b110
```

          
        
        
          Bitwise Xor
          
```zig
a ^ b
a ^= b
```

          
            
              
- [Integers](#Integers)
            
          
          
            
              
- Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
            
          
          
            
```zig
0b011 ^ 0b101 == 0b110
```

          
        
        
          Bitwise Not
          
```zig
~a
```

          
            
              
- [Integers](#Integers)
            
          
          
          
            
```zig
~@as(u8, 0b10101111) == 0b01010000
```

          
        
        
          Defaulting Optional Unwrap
          
```zig
a orelse b
```

          
            
              
- [Optionals](#Optionals)
            
          
          If `a` is `null`,
          returns `b` ("default value"),
          otherwise returns the unwrapped value of `a`.
          Note that `b` may be a value of type [noreturn](#noreturn).
          
          
            
```zig
const value: ?u32 = null;
const unwrapped = value orelse 1234;
unwrapped == 1234
```

          
        
        
          Optional Unwrap
          
```zig
a.?
```

          
            
              
- [Optionals](#Optionals)
            
          
          
            Equivalent to:
            
```zig
a orelse unreachable
```

          
          
            
```zig
const value: ?u32 = 5678;
value.? == 5678
```

          
        
        
          Defaulting Error Unwrap
          
```zig
a catch b
a catch |err| b
```

          
            
              
- [Error Unions](#Errors)
            
          
          If `a` is an `error`,
          returns `b` ("default value"),
          otherwise returns the unwrapped value of `a`.
          Note that `b` may be a value of type [noreturn](#noreturn).
`err` is the `error` and is in scope of the expression `b`.
          
          
            
```zig
const value: anyerror!u32 = error.Broken;
const unwrapped = value catch 1234;
unwrapped == 1234
```

          
        
        
          Logical And
          
```zig
a and b
```

          
            
              
- [bool](#Primitive-Types)
            
          
          
          If `a` is `false`, returns `false`
          without evaluating `b`. Otherwise, returns `b`.
          
          
            
```zig
(false and true) == false
```

          
        
        
          Logical Or
          
```zig
a or b
```

          
            
              
- [bool](#Primitive-Types)
            
          
          
              If `a` is `true`,
              returns `true` without evaluating
              `b`. Otherwise, returns
              `b`.
          
          
            
```zig
(false or true) == true
```

          
        
        
          Boolean Not
          
```zig
!a
```

          
            
              
- [bool](#Primitive-Types)
            
          
          
          
            
```zig
!false == true
```

          
        
        
          Equality
          
```zig
a == b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
              
- [bool](#Primitive-Types)
              
- [type](#Primitive-Types)
              
- [packed struct](#packed-struct)
            
          
          
              Returns `true` if a and b are equal, otherwise returns `false`.
            Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
          
          
            
```zig
(1 == 1) == true
```

          
        
        
          Null Check
          
```zig
a == null
```

          
            
              
- [Optionals](#Optionals)
            
          
          
              Returns `true` if a is `null`, otherwise returns `false`.
          
          
            
```zig
const value: ?u32 = null;
(value == null) == true
```

          
        
        
          Inequality
          
```zig
a != b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
              
- [bool](#Primitive-Types)
              
- [type](#Primitive-Types)
            
          
          
              Returns `false` if a and b are equal, otherwise returns `true`.
            Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
          
          
            
```zig
(1 != 1) == false
```

          
        
        
          Non-Null Check
          
```zig
a != null
```

          
            
              
- [Optionals](#Optionals)
            
          
          
              Returns `false` if a is `null`, otherwise returns `true`.
          
          
            
```zig
const value: ?u32 = null;
(value != null) == false
```

          
        
        
          Greater Than
          
```zig
a > b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
              Returns `true` if a is greater than b, otherwise returns `false`.
            Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
          
          
            
```zig
(2 > 1) == true
```

          
        
        
          Greater or Equal
          
```zig
a >= b
```

          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
              Returns `true` if a is greater than or equal to b, otherwise returns `false`.
            Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
          
          
            
```zig
(2 >= 1) == true
```

          
        
        
          Less Than
          
```zig
a 
          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
              Returns `true` if a is less than b, otherwise returns `false`.
            Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
          
          
            
```zig
(1 2) == true
```

          
        
        
          Lesser or Equal
          
```zig
a 
          
            
              
- [Integers](#Integers)
              
- [Floats](#Floats)
            
          
          
              Returns `true` if a is less than or equal to b, otherwise returns `false`.
            Invokes [Peer Type Resolution](#Peer-Type-Resolution) for the operands.
          
          
            
```zig
(1 2) == true
```

          
        
        
          Array Concatenation
          
```zig
a ++ b
```

          
            
              
- [Arrays](#Arrays)
            
          
          
            
              
- Only available when the lengths of both `a` and `b` are [compile-time known](#comptime).
            
          
          
            
```zig
const mem = @import("std").mem;
const array1 = [_]u32{1,2};
const array2 = [_]u32{3,4};
const together = array1 ++ array2;
mem.eql(u32, &together, &[_]u32{1,2,3,4})
```

          
        
        
          Array Multiplication
          
```zig
a ** b
```

          
            
              
- [Arrays](#Arrays)
            
          
          
            
              
- Only available when the length of `a` and `b` are [compile-time known](#comptime).
            
          
          
            
```zig
const mem = @import("std").mem;
const pattern = "ab" ** 3;
mem.eql(u8, pattern, "ababab")
```

          
        
        
          Pointer Dereference
          
```zig
a.*
```

          
            
              
- [Pointers](#Pointers)
            
          
          
            Pointer dereference.
          
          
            
```zig
const x: u32 = 1234;
const ptr = &x;
ptr.* == 1234
```

          
        
        
          Address Of
          
```zig
&a
```

          
            All types
          
          
          
          
            
```zig
const x: u32 = 1234;
const ptr = &x;
ptr.* == 1234
```

          
        
        
          Error Set Merge
          
```zig
a || b
```

          
            
              
- [Error Set Type](#Error-Set-Type)
            
          
          
              [Merging Error Sets](#Merging-Error-Sets)
          
          
            
```zig
const A = error{One};
const B = error{Two};
(A || B) == error{One, Two}
```

          
        
        
      
      
      
      
## [Precedence](#toc-Precedence) §

      
```zig
x() x[] x.y x.* x.?
a!b
x{}
!x -x -%x ~x &x ?x
* / % ** *% *| ||
+ - ++ +% -% +| -|
> orelse catch
== !=  =
and
or
= *= *%= *|= /= %= += +%= +|= -= -%= -|= >= &= ^= |=
```