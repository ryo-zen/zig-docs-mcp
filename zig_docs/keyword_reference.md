# Keyword Reference

Keyword
    Description

```zig
addrspace
```

      The `addrspace` keyword.

- TODO add documentation for addrspace

```zig
align
```

      `align` can be used
to specify the alignment of a pointer.
      It can also be used after a variable or function declaration
 to specify the alignment of pointers to that variable or function.

- See also [Alignment](#Alignment)

```zig
allowzero
```

      The pointer attribute `allowzero` allows a pointer to have address zero.

- See also [allowzero](#allowzero)

```zig
and
```

      The boolean operator `and`.

- See also [Operators](#Operators)

```zig
anyframe
```

      `anyframe` can be used as a type for variables which hold pointers to function frames.

- See also [Async Functions](#Async-Functions)

```zig
anytype
```

      Function parameters can be declared with `anytype` in place of the type.
      The type will be inferred where the function is called.

- See also [Function Parameter Type Inference](#Function-Parameter-Type-Inference)

```zig
asm
```

      `asm` begins an inline assembly expression. This allows for directly controlling the machine code generated on compilation.

- See also [Assembly](#Assembly)

```zig
break
```

      `break` can be used with a block label to return a value from the block.
      It can also be used to exit a loop before iteration completes naturally.

- See also [Blocks](#Blocks), [while](#while), [for](#for)

```zig
callconv
```

      `callconv` can be used to specify the calling convention in a function type.

- See also [Functions](#Functions)

```zig
catch
```

      `catch` can be used to evaluate an expression if the expression before it evaluates to an error.
      The expression after the `catch` can optionally capture the error value.

- See also [catch](#catch), [Operators](#Operators)

```zig
comptime
```

      `comptime` before a declaration can be used to label variables or function parameters as known at compile time.
      It can also be used to guarantee an expression is run at compile time.

- See also [comptime](#comptime)

```zig
const
```

      `const` declares a variable that can not be modified.
      Used as a pointer attribute, it denotes the value referenced by the pointer cannot be modified.

- See also [Variables](#Variables)

```zig
continue
```

      `continue` can be used in a loop to jump back to the beginning of the loop.

- See also [while](#while), [for](#for)

```zig
defer
```

      `defer` will execute an expression when control flow leaves the current block.

- See also [defer](#defer)

```zig
else
```

      `else` can be used to provide an alternate branch for `if`, `switch`,
      `while`, and `for` expressions.

- If used after an if expression, the else branch will be executed if the test value returns false, null, or an error.

- If used within a switch expression, the else branch will be executed if the test value matches no other cases.

- If used after a loop expression, the else branch will be executed if the loop finishes without breaking.

- See also [if](#if), [switch](#switch), [while](#while), [for](#for)

```zig
enum
```

      `enum` defines an enum type.

- See also [enum](#enum)

```zig
errdefer
```

      `errdefer` will
execute an expression when control flow leaves the current block if the
function returns an error, the errdefer expression can capture the
unwrapped value.

- See also [errdefer](#errdefer)

```zig
error
```

      `error` defines an error type.

- See also [Errors](#Errors)

```zig
export
```

      `export` makes a function or variable externally visible in the generated object file.
      Exported functions default to the C calling convention.

- See also [Functions](#Functions)

```zig
extern
```

      `extern` can be used to declare a function or variable that will be resolved at link time, when linking statically
      or at runtime, when linking dynamically.

- See also [Functions](#Functions)

```zig
fn
```

      `fn` declares a function.

- See also [Functions](#Functions)

```zig
for
```

      A `for` expression can be used to iterate over the elements of a slice, array, or tuple.

- See also [for](#for)

```zig
if
```

      An `if` expression can test boolean expressions, optional values, or error unions.
      For optional values or error unions, the if expression can capture the unwrapped value.

- See also [if](#if)

```zig
inline
```

      `inline` can be used to label a loop expression such that it will be unrolled at compile time.
      It can also be used to force a function to be inlined at all call sites.

- See also [inline while](#inline-while), [inline for](#inline-for), [Functions](#Functions)

```zig
linksection
```

      The `linksection` keyword can be used to specify what section the function or global variable will be put into (e.g. `.text`).

```zig
noalias
```

      The `noalias` keyword.

- TODO add documentation for noalias

```zig
noinline
```

      `noinline` disallows function to be inlined in all call sites.

- See also [Functions](#Functions)

```zig
nosuspend
```

      The `nosuspend` keyword can be used in front of a block, statement or expression, to mark a scope where no suspension points are reached.
      In particular, inside a `nosuspend` scope:

- Using the `suspend` keyword results in a compile error.

- Using `await` on a function frame which hasn't completed yet results in safety-checked [Illegal Behavior](#Illegal-Behavior).

- Calling an async function may result in safety-checked [Illegal Behavior](#Illegal-Behavior), because it's equivalent to `await async some_async_fn()`, which contains an `await`.

      Code inside a `nosuspend` scope does not cause the enclosing function to become an [async function](#Async-Functions).

- See also [Async Functions](#Async-Functions)

```zig
opaque
```

      `opaque` defines an opaque type.

- See also [opaque](#opaque)

```zig
or
```

      The boolean operator `or`.

- See also [Operators](#Operators)

```zig
orelse
```

      `orelse` can be used to evaluate an expression if the expression before it evaluates to null.

- See also [Optionals](#Optionals), [Operators](#Operators)

```zig
packed
```

      The `packed` keyword before a struct definition changes the struct's in-memory layout
      to the guaranteed `packed` layout.

- See also [packed struct](#packed-struct)

```zig
pub
```

      The `pub` in front of a top level declaration makes the declaration available
      to reference from a different file than the one it is declared in.

- See also [import](#import)

```zig
resume
```

      `resume` will continue execution of a function frame after the point the function was suspended.

```zig
return
```

      `return` exits a function with a value.

- See also [Functions](#Functions)

```zig
struct
```

      `struct` defines a struct.

- See also [struct](#struct)

```zig
suspend
```

      `suspend` will cause control flow to return to the call site or resumer of the function.
      `suspend` can also be used before a block within a function,
      to allow the function access to its frame before control flow returns to the call site.

```zig
switch
```

      A `switch` expression can be used to test values of a common type.
      `switch` cases can capture field values of a [Tagged union](#Tagged-union).

- See also [switch](#switch)

```zig
test
```

      The `test` keyword can be used to denote a top-level block of code
      used to make sure behavior meets expectations.

- See also [Zig Test](#Zig-Test)

```zig
threadlocal
```

      `threadlocal` can be used to specify a variable as thread-local.

- See also [Thread Local Variables](#Thread-Local-Variables)

```zig
try
```

      `try` evaluates an error union expression.
      If it is an error, it returns from the current function with the same error.
      Otherwise, the expression results in the unwrapped value.

- See also [try](#try)

```zig
union
```

      `union` defines a union.

- See also [union](#union)

```zig
unreachable
```

      `unreachable` can be used to assert that control flow will never happen upon a particular location.
      Depending on the build mode, `unreachable` may emit a panic.

- Emits a panic in `Debug` and `ReleaseSafe` mode, or when using zig test.

- Does not emit a panic in `ReleaseFast` and `ReleaseSmall` mode.

- See also [unreachable](#unreachable)

```zig
var
```

      `var` declares a variable that may be modified.

- See also [Variables](#Variables)

```zig
volatile
```

      `volatile` can be used to denote loads or stores of a pointer have side effects.
      It can also modify an inline assembly expression to denote it has side effects.

- See also [volatile](#volatile), [Assembly](#Assembly)

```zig
while
```

      A `while` expression can be used to repeatedly test a boolean, optional, or error union expression,
      and cease looping when that expression evaluates to false, null, or an error, respectively.

- See also [while](#while)
