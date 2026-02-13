# Classic Design Patterns in Zig

How traditional Gang of Four and other classic design patterns translate to Zig's paradigm.

**Key insight**: Many OOP patterns exist to work around language limitations. Zig often provides more direct solutions.

---

## 🟢 Highly Relevant Patterns

These patterns are natural and idiomatic in Zig.

### ✅ RAII (Resource Acquisition Is Initialization)

**Classic intent**: Tie resource lifetime to object scope, ensure cleanup happens automatically.

**In Zig**: `defer` and `errdefer` provide explicit, guaranteed cleanup without needing classes.

```zig
// ✅ Zig's RAII with defer
const buffer = try allocator.alloc(u8, size);
defer allocator.free(buffer); // Guaranteed cleanup

// Works even with errors
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close(); // Guaranteed cleanup

try processFile(file); // If this fails, file still closes
```

**See**: [Defer Cleanup Pattern](memory/defer_cleanup.md), [errdefer Rollback](memory/errdefer_rollback.md)

**Test code**: Already exists in our pattern tests!

---

### ✅ Dependency Injection

**Classic intent**: Pass dependencies to objects rather than having them create dependencies.

**In Zig**: Extremely common and idiomatic. Allocators are the prime example.

```zig
// ✅ Dependency injection in Zig
fn parseData(allocator: std.mem.Allocator, input: []const u8) ![]Token {
    // Function receives allocator, doesn't create it
    const tokens = try allocator.alloc(Token, estimated_count);
    // ...
}

// Caller controls the allocation strategy
const tokens = try parseData(arena.allocator(), input);
// or
const tokens = try parseData(gpa.allocator(), input);
```

**Why it matters**:
- Testability: Inject `testing.allocator` for leak detection
- Flexibility: Choose allocation strategy at call site
- Composability: Functions work with any allocator

**See**: [Testing with Allocators](testing/allocator_testing.md)

**Test code**: Should add example showing DI with custom interfaces

---

### ✅ Builder Pattern

**Classic intent**: Separate construction from representation, allow step-by-step object building.

**In Zig**: Use struct initialization with default values and builder methods.

```zig
const HttpRequest = struct {
    method: []const u8 = "GET",
    url: []const u8,
    headers: []Header = &.{},
    body: ?[]const u8 = null,
    timeout_ms: u32 = 5000,

    // Builder-style methods
    pub fn withMethod(self: @This(), method: []const u8) @This() {
  var result = self;
  result.method = method;
  return result;
    }

    pub fn withTimeout(self: @This(), ms: u32) @This() {
  var result = self;
  result.timeout_ms = ms;
  return result;
    }
};

// Usage - clean builder syntax
const request = HttpRequest{ .url = "api.example.com" }
    .withMethod("POST")
    .withTimeout(10000);
```

**Test code**: Should create builder pattern example

---

### ✅ Lazy Initialization

**Classic intent**: Delay expensive initialization until first use.

**In Zig**: Use optional types (`?T`) or explicit init flags.

```zig
const CachedData = struct {
    cached_result: ?ComputedValue = null,

    pub fn get(self: *@This()) !ComputedValue {
  if (self.cached_result) |result| {
      return result; // Already computed
  }

  // Lazy initialization on first access
  const result = try expensiveComputation();
  self.cached_result = result;
  return result;
    }
};
```

**Test code**: Should add lazy initialization example

---

## 🟡 Somewhat Relevant Patterns

These can be useful but may not be idiomatic Zig.

### ⚠️ Factory Method

**Classic intent**: Let subclasses decide which class to instantiate.

**In Zig**: Just use functions that return types. No inheritance needed.

```zig
// ✅ Simple factory in Zig
fn createParser(format: Format) type {
    return switch (format) {
  .json => JsonParser,
  .xml => XmlParser,
  .yaml => YamlParser,
    };
}

// Usage
const Parser = createParser(.json);
var parser = Parser.init(allocator);
```

**When to use**: Rarely needed. Usually just call a function directly.

**Test code**: Not needed - too simple

---

### ⚠️ Object Pool

**Classic intent**: Reuse expensive objects instead of allocating/deallocating.

**In Zig**: Consider using Arena allocator instead for most cases.

```zig
// ❌ Complex object pool (usually overkill)
var pool = ObjectPool(Connection).init(allocator);

// ✅ Zig alternative: Arena allocator
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();

// All allocations freed at once, no individual tracking needed
const conn1 = try createConnection(arena.allocator());
const conn2 = try createConnection(arena.allocator());
```

**When to use**: For truly expensive resources like thread pools, connection pools. Not for general allocation.

**See**: [Arena Allocator Pattern](memory/arena_allocator.md)

**Test code**: Not needed - use arena instead

---

## 🔴 Not Recommended in Zig

These patterns either work around OOP limitations or promote anti-patterns in Zig.

### ❌ Singleton

**Classic intent**: Ensure only one instance exists globally.

**Why not in Zig**: Global mutable state is an anti-pattern. Use dependency injection instead.

```zig
// ❌ Singleton (don't do this)
var global_config: Config = undefined;
var initialized = false;

pub fn getConfig() *Config {
    if (!initialized) {
  global_config = Config.init();
  initialized = true;
    }
    return &global_config;
}

// ✅ Dependency injection (do this)
fn processData(config: *const Config, data: []const u8) !void {
    // Caller passes config, function doesn't own it
}
```

**Test code**: Not needed - anti-pattern

---

### ❌ Abstract Factory

**Classic intent**: Provide interface for creating families of related objects.

**Why not in Zig**: No inheritance. Use `comptime` type generation or tagged unions instead.

```zig
// ✅ Zig alternative: comptime type generation
fn createUITheme(comptime theme: Theme) type {
    return struct {
  const Button = switch (theme) {
      .dark => DarkButton,
      .light => LightButton,
  };
  const Input = switch (theme) {
      .dark => DarkInput,
      .light => LightInput,
  };
    };
}

const UI = createUITheme(.dark);
var button = UI.Button.init();
```

**Test code**: Not needed - use comptime patterns

---

### ❌ Prototype

**Classic intent**: Clone objects to create new instances.

**Why not in Zig**: No built-in cloning protocol. Just copy struct data.

```zig
// ✅ Zig approach: explicit copying
const original = Config{ .timeout = 30, .retries = 3 };
var copy = original; // Structs are value types, this copies

// Or explicit clone method if needed
pub fn clone(self: @This(), allocator: Allocator) !@This() {
    var result = self;
    result.name = try allocator.dupe(u8, self.name);
    return result;
}
```

**Test code**: Not needed - trivial

---

### ❌ Multiton

**Classic intent**: Multiple named singletons.

**Why not in Zig**: Same issues as Singleton. Use dependency injection.

**Test code**: Not needed - anti-pattern

---

## Summary: What to Implement

### ✅ Write test code for:
1. **Dependency Injection** - Show allocator injection, custom interface injection
2. **Builder Pattern** - Struct initialization with builder methods
3. **Lazy Initialization** - Optional types and init-on-demand

### ✅ Already have test code for:
1. **RAII (defer/errdefer)** - See [defer cleanup tests](../zig_docs_std/Examples/std.mem.ValidationAllocator.tests.zig)

### ⚠️ Document but don't test:
1. **Factory Method** - Too simple, just use functions
2. **Object Pool** - Use arena allocator instead
3. **Abstract Factory** - Use comptime

### ❌ Explicitly recommend against:
1. **Singleton** - Global state anti-pattern
2. **Multiton** - Same issues as singleton
3. **Prototype** - Not needed, structs are value types

---

## Zig Philosophy vs OOP Patterns

**Why many patterns don't apply**:

1. **No inheritance** → Patterns based on polymorphism don't translate
2. **Comptime** → Type generation at compile time replaces many runtime patterns
3. **Explicit over implicit** → Zig favors explicit passing over global access
4. **Value semantics** → Structs are copied by default, no need for cloning protocols
5. **Manual memory management** → RAII through defer, not destructors

**What Zig provides instead**:
- **Comptime** for metaprogramming (replaces factories, templates)
- **Tagged unions** for polymorphism without inheritance
- **defer/errdefer** for RAII without classes
- **Interfaces via fat pointers** for runtime polymorphism when needed
- **Explicit allocators** for dependency injection

---

---

## 🟡 Structural Patterns

Patterns for organizing code structure and composition.

### ✅ Adapter/Wrapper ⭐ (Very Common in Zig!)

**Classic intent**: Convert interface of a class into another interface clients expect.

**In Zig**: Extremely common! Wrap allocators, readers, writers, any interface.

**Test code**: ✅ [See adapter tests](../zig_docs_std/Examples/zig_patterns.adapter.tests.zig)

**Examples**:
- `std.mem.validationWrap()` - Wrap allocator with validation
- Reader/Writer adapters - Adapt any type to Reader/Writer interface
- Legacy C API adapters - Make old APIs feel idiomatic

---

### ✅ Facade

**Classic intent**: Provide simplified interface to complex subsystem.

**In Zig**: Very useful for hiding stdlib complexity or simplifying APIs.

**Example**:
```zig
// Complex stdlib API
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();
var buf_reader = std.io.bufferedReader(file.reader());
const reader = buf_reader.reader();

// Facade: simplified interface
pub fn readTextFile(path: []const u8, allocator: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 1024 * 1024);
}
```

**Test code**: Could add, but pattern is self-evident

---

### ⚠️ Proxy

**Classic intent**: Placeholder that controls access to another object.

**In Zig**: Useful for lazy loading, access control, logging.

**Example**: Lazy-loading proxy (see Lazy Initialization pattern)

**Test code**: Covered by Lazy Init tests

---

### ⚠️ Decorator

**Classic intent**: Attach responsibilities to object dynamically.

**In Zig**: Use wrapper structs or comptime composition.

**Example**: Stacking adapters (logging allocator wrapping validating allocator wrapping base allocator)

**Test code**: Demonstrated in adapter stacking test

---

### ❌ Bridge, Composite, Flyweight

**Why not**: Designed for class hierarchies. Zig uses different approaches:
- **Bridge**: Use comptime or tagged unions instead
- **Composite**: Tree structures work fine, but no need for polymorphic component interface
- **Flyweight**: Manual memory optimization when needed

---

## 🟢 Behavioral Patterns

Patterns for object communication and responsibility.

### ✅ Strategy ⭐ (Fundamental in Zig!)

**Classic intent**: Define family of interchangeable algorithms.

**In Zig**: Function pointers, comptime, or fat pointers (vtables).

**Test code**: ✅ [See strategy tests](../zig_docs_std/Examples/zig_patterns.strategy.tests.zig)

**Examples**:
- `std.sort` with custom comparators
- Compression strategies (runtime selection)
- Validation strategies (comptime composition)

---

### ✅ Iterator ⭐ (Built into Zig!)

**Classic intent**: Access elements sequentially without exposing representation.

**In Zig**: Extensively used throughout stdlib!

**Examples we've documented**:
- `std.mem.SplitIterator` - [docs](../zig_docs_std/Namespaces/mem/std.mem.SplitIterator.md)
- `std.mem.WindowIterator` - [docs](../zig_docs_std/Namespaces/mem/std.mem.WindowIterator.md) | [tests](../zig_docs_std/Examples/std.mem.WindowIterator.tests.zig)
- `std.mem.TokenIterator` - [docs](../zig_docs_std/Namespaces/mem/std.mem.TokenIterator.md)

**Test code**: ✅ Already extensively documented!

---

### ✅ Observer (Publish/Subscribe)

**Classic intent**: Define one-to-many dependency for notifications.

**In Zig**: Function callbacks, arrays of listeners.

**Example**:
```zig
const EventEmitter = struct {
    listeners: std.ArrayList(*const fn(Event) void),

    pub fn on(self: *@This(), callback: *const fn(Event) void) !void {
  try self.listeners.append(self.allocator, callback);
    }

    pub fn emit(self: @This(), event: Event) void {
  for (self.listeners.items) |listener| {
      listener(event);
  }
    }
};
```

**Test code**: Could add simple event system example

---

### ✅ Command

**Classic intent**: Encapsulate request as object.

**In Zig**: Function pointers with context, or tagged unions.

**Example**:
```zig
const Command = union(enum) {
    move: struct { x: i32, y: i32 },
    rotate: f32,
    scale: f32,

    pub fn execute(self: Command, target: *Object) void {
  switch (self) {
      .move => |pos| target.moveTo(pos.x, pos.y),
      .rotate => |angle| target.rotate(angle),
      .scale => |factor| target.scale(factor),
  }
    }
};
```

**Test code**: Pattern is straightforward with tagged unions

---

### ✅ Null Object

**Classic intent**: Provide default object to avoid null checks.

**In Zig**: Optional types (`?T`) solve this elegantly!

**Example**:
```zig
// ❌ Classic null object pattern (unnecessary in Zig)
const NullLogger = struct {
    pub fn log(self: *@This(), msg: []const u8) void { _ = self; _ = msg; }
};

// ✅ Zig way: optional types
const logger: ?Logger = null;
if (logger) |l| l.log("message"); // Clean, type-safe
```

**Test code**: Not needed - use optionals instead

---

### ⚠️ Chain of Responsibility

**Classic intent**: Pass request along chain of handlers.

**In Zig**: Array of handlers, or error handling chains.

**Example**:
```zig
fn handleRequest(handlers: []Handler, request: Request) !Response {
    for (handlers) |handler| {
  if (handler.canHandle(request)) {
      return handler.handle(request);
  }
    }
    return error.NoHandlerFound;
}
```

---

### ⚠️ State

**Classic intent**: Alter behavior when internal state changes.

**In Zig**: Tagged unions represent state + behavior.

**Example**:
```zig
const Connection = union(enum) {
    disconnected,
    connecting,
    connected: struct { socket: Socket },

    pub fn send(self: *@This(), data: []const u8) !void {
  switch (self.*) {
      .connected => |conn| try conn.socket.write(data),
      else => return error.NotConnected,
  }
    }
};
```

---

### ❌ Template Method, Visitor, Mediator, Memento

**Why not**: Designed for inheritance hierarchies.

- **Template Method**: Use composition or pass functions as parameters
- **Visitor**: Use tagged unions with switch statements
- **Mediator**: Just use a coordinator struct
- **Memento**: Copy structs (value semantics) or serialize state

---

## Pattern Summary Table

| Pattern | Relevance | Zig Approach | Test Code |
|---------|-----------|--------------|-----------|
| **Creational** | | | |
| RAII | ✅ Essential | `defer`/`errdefer` | ✅ [tests](../zig_docs_std/Examples/std.mem.ValidationAllocator.tests.zig) |
| Dependency Injection | ✅ Essential | Pass allocators/interfaces | ✅ [tests](../zig_docs_std/Examples/zig_patterns.dependency_injection.tests.zig) |
| Builder | ✅ Common | Struct defaults + methods | ✅ [tests](../zig_docs_std/Examples/zig_patterns.builder.tests.zig) |
| Lazy Initialization | ✅ Common | Optional types | ✅ [tests](../zig_docs_std/Examples/zig_patterns.lazy_initialization.tests.zig) |
| Factory | ⚠️ Sometimes | Functions returning types | — |
| Singleton | ❌ Anti-pattern | Use DI instead | — |
| **Structural** | | | |
| Adapter | ✅ Very Common | Wrapper structs | ✅ [tests](../zig_docs_std/Examples/zig_patterns.adapter.tests.zig) |
| Facade | ✅ Common | Simplify complex APIs | — |
| Proxy | ⚠️ Sometimes | Wrapper with control logic | — |
| Decorator | ⚠️ Sometimes | Stacked wrappers | Shown in adapter tests |
| Others | ❌ Rare | Use simpler Zig idioms | — |
| **Behavioral** | | | |
| Strategy | ✅ Essential | Function pointers, comptime | ✅ [tests](../zig_docs_std/Examples/zig_patterns.strategy.tests.zig) |
| Iterator | ✅ Built-in | Stdlib iterators | ✅ [extensive docs](../zig_docs_std/Namespaces/mem/) |
| Observer | ✅ Common | Callback arrays | — |
| Command | ✅ Common | Tagged unions | — |
| Null Object | ✅ Solved | Optional types (`?T`) | — |
| State | ⚠️ Sometimes | Tagged unions | — |
| Chain of Responsibility | ⚠️ Sometimes | Handler arrays | — |
| Others | ❌ Rare | Simpler alternatives exist | — |

---

## Key Takeaways

1. **Many patterns solve OOP problems Zig doesn't have**
   - No inheritance → Bridge, Template Method, Visitor unnecessary
   - Value semantics → No need for Prototype/Clone protocols

2. **Zig provides better alternatives**
   - `defer`/`errdefer` → RAII without destructors
   - Comptime → Replaces many factory patterns
   - Tagged unions → State, Command, Visitor patterns
   - Optional types → Null Object pattern solved

3. **Focus on Zig idioms, not patterns**
   - Explicit over implicit
   - Composition over inheritance (which doesn't exist)
   - Comptime for zero-cost abstractions
   - Pass interfaces explicitly (DI)

4. **Test the important ones**
   - ✅ 6 patterns with comprehensive test suites
   - These cover 80% of real-world use cases
   - Others are either built-in or unnecessary

---

## See Also

- [Zen of Zig](zen.md) - Why Zig does things differently
- [Memory Patterns](memory/) - RAII and resource management
- [Iterator Patterns](iterators/) - Split, tokenize, window iteration
- [Testing Patterns](testing/) - Dependency injection with allocators
- [Zig Language Reference](https://ziglang.org/documentation/master/)
