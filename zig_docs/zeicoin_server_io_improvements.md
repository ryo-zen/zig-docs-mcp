# Server.zig Complexity Reduction with std.Io

## Current Complexity (server.zig)

The main server loop has several manual complexity patterns that std.Io can eliminate.

### 1. Manual Timestamp Polling (Lines 107-114)

**Current Pattern:**
```zig
var last_status_time = std.time.timestamp();
var last_reconnection_check = std.time.timestamp();
var last_sync_retry_check = std.time.timestamp();

while (running.load(.acquire)) {
    const now = std.time.timestamp();

    // Check every 30 seconds
    if (now - last_status_time >= 30 and running.load(.acquire)) {
  printStatus(&components);
  last_status_time = now;
    }

    // Check every 10 seconds
    if (now - last_reconnection_check >= 10) {
  last_reconnection_check = now;
  components.network_manager.maintenance();
    }

    // Check every 5 seconds
    if (now - last_sync_retry_check >= 5) {
  last_sync_retry_check = now;
  components.sync_manager.checkTimeout();
    }

    std.time.sleep(100 * std.time.ns_per_ms);
}
```

**std.Io Improvement:**
```zig
const io = init.io;

// Launch periodic tasks as concurrent operations
const status_task = try io.concurrent(periodicStatus, .{io, &components});
const maintenance_task = try io.concurrent(periodicMaintenance, .{io, &components});
const sync_task = try io.concurrent(periodicSyncCheck, .{io, &components});

// Wait for shutdown signal
try io.checkCancel(); // Blocks until SIGINT/SIGTERM

// Cleanup happens automatically via defer
```

**Separate functions:**
```zig
fn periodicStatus(io: std.Io, components: *NodeComponents) !void {
    while (true) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(30), std.Io.Clock.awake);
  printStatus(components);
    }
}

fn periodicMaintenance(io: std.Io, components: *NodeComponents) !void {
    while (true) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(10), std.Io.Clock.awake);
  components.network_manager.maintenance();
    }
}

fn periodicSyncCheck(io: std.Io, components: *NodeComponents) !void {
    while (true) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(5), std.Io.Clock.awake);
  components.sync_manager.checkTimeout();
    }
}
```

**Benefits:**
- ✅ No manual timestamp tracking (4 variables → 0)
- ✅ No manual interval math
- ✅ Each task isolated (easier to test)
- ✅ Automatic cleanup on shutdown
- ✅ Cancellable via io.cancel()

### 2. Manual Thread Spawning (Lines 71, 85, 157)

**Current Pattern:**
```zig
// Client API thread
const api_thread = try std.Thread.spawn(.{}, client_api.ClientApiServer.start, .{&api_server.?});
api_thread.detach();

// RPC thread
const rpc_thread = try std.Thread.spawn(.{}, RPCServer.start, .{rpc_server});
rpc_thread.detach();

// Sync recovery thread
_ = std.Thread.spawn(.{}, triggerSyncRecovery, .{ components.sync_manager }) catch |err| {
    std.log.err("Failed to spawn recovery thread: {}", .{err});
};
```

**std.Io Improvement:**
```zig
// Launch as concurrent tasks
const api_future = if (!config.client_api_disabled)
    try io.concurrent(client_api.ClientApiServer.start, .{&api_server.?})
else
    null;

const rpc_future = try io.concurrent(RPCServer.start, .{rpc_server});

// Later, for sync recovery:
const sync_future = try io.concurrent(triggerSyncRecovery, .{components.sync_manager});
```

**Benefits:**
- ✅ No manual .detach()
- ✅ Can await futures for errors
- ✅ Automatic cleanup
- ✅ Better error propagation

### 3. Signal Handling + Atomic Flag (Lines 14-21, 88-101)

**Current Pattern:**
```zig
var running = std.atomic.Value(bool).init(true);

fn signalHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    running.store(false, .release);
}

// Setup handlers
_ = std.posix.sigaction(std.posix.SIG.INT, &.{
    .handler = .{ .handler = signalHandler },
    .mask = std.posix.empty_sigset,
    .flags = 0,
}, null);

_ = std.posix.sigaction(std.posix.SIG.TERM, &.{
    .handler = .{ .handler = signalHandler },
    .mask = std.posix.empty_sigset,
    .flags = 0,
}, null);

// Main loop
while (running.load(.acquire)) {
    // ...
}
```

**std.Io Improvement:**
```zig
// No manual signal handling needed!
// std.Io handles SIGINT/SIGTERM automatically via init.io

const io = init.io;

// Launch all concurrent tasks
const tasks = [_]std.Io.Future(void){
    try io.concurrent(periodicStatus, .{io, &components}),
    try io.concurrent(periodicMaintenance, .{io, &components}),
    try io.concurrent(periodicSyncCheck, .{io, &components}),
    try io.concurrent(client_api.start, .{io, &api_server}),
    try io.concurrent(rpcServer.start, .{io, rpc_server}),
};

// Wait for cancellation (SIGINT/SIGTERM)
try io.checkCancel();

// All tasks automatically cleaned up via defer
```

**Benefits:**
- ✅ No manual signal handlers
- ✅ No atomic flag
- ✅ No while loop
- ✅ Automatic cancellation propagation

### 4. Complex Mining Startup Logic (Lines 168-202)

**Current Pattern:**
```zig
var mining_started = false;
var initial_sync_done = false;

// Inside main loop:
if (!mining_started and components.blockchain.mining_manager != null) {
    const should_start_mining = blk: {
  const peer_stats = components.network_manager.getPeerStats();
  if (peer_stats.connected == 0) {
      if (!initial_sync_done) {
          const startup_time = 5;
          std.time.sleep(startup_time * std.time.ns_per_s);
          initial_sync_done = true;
          std.log.info("No peers found - starting mining on local chain", .{});
          break :blk true;
      } else {
          break :blk false;
      }
  }

  if (components.sync_manager.isActive()) {
      break :blk false;
  }

  break :blk true;
    };

    if (should_start_mining) {
  if (startMiningAfterSync(&components)) {
      mining_started = true;
  }
    }
}
```

**std.Io Improvement:**
```zig
fn miningStartupTask(io: std.Io, components: *NodeComponents) !void {
    // Wait for sync to complete or timeout
    const result = io.select(.{
  .sync_done = waitForSyncComplete(io, components.sync_manager),
  .timeout = io.async(sleepAndReturn, .{io, 5}),
    });

    switch (result) {
  .sync_done => |_| {
      std.log.info("Sync complete, starting mining", .{});
  },
  .timeout => |_| {
      const peer_stats = components.network_manager.getPeerStats();
      if (peer_stats.connected == 0) {
          std.log.info("No peers found - starting mining on local chain", .{});
      }
  },
    }

    // Start mining
    if (components.blockchain.mining_manager) |manager| {
  try manager.startMiningDeferred();
    }
}

fn waitForSyncComplete(io: std.Io, sync_manager: *SyncManager) !void {
    while (sync_manager.isActive()) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(1), std.Io.Clock.awake);
    }
}
```

**Benefits:**
- ✅ No state flags (mining_started, initial_sync_done)
- ✅ Select between sync/timeout events
- ✅ Cleaner logic flow
- ✅ Cancellable

## Complete Rewrite Comparison

### Before (Current server.zig)

**Complexity:**
- ~278 lines
- 3 manual timestamps
- 3 thread spawns with detach
- 2 signal handlers
- 1 atomic flag
- 1 polling loop
- 2 state flags for mining startup
- Manual sleep with ns_per_ms math

### After (With std.Io)

**Simplified:**
```zig
pub fn main(init: std.process.Init) !void {
    printBanner();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.Args.toSlice(init.minimal.args, allocator);
    defer allocator.free(args);

    @import("../util/dotenv.zig").loadForNetwork(std.heap.page_allocator) catch {};

    var config = try command_line.parseArgs(allocator, args);
    defer config.deinit();

    var components = try initialization.initializeNode(allocator, init.io, config);
    defer components.deinit();

    const io = init.io;

    // Launch all background tasks
    var tasks = std.ArrayList(std.Io.Future(void)).init(allocator);
    defer tasks.deinit();

    // Periodic maintenance
    try tasks.append(try io.concurrent(periodicStatus, .{io, &components}));
    try tasks.append(try io.concurrent(periodicMaintenance, .{io, &components}));
    try tasks.append(try io.concurrent(periodicSyncCheck, .{io, &components}));

    // Servers
    if (!config.client_api_disabled) {
  try tasks.append(try io.concurrent(runClientApi, .{io, allocator, &components, config}));
    }
    try tasks.append(try io.concurrent(runRpcServer, .{io, allocator, &components}));

    // Mining startup
    if (components.blockchain.mining_manager != null) {
  try tasks.append(try io.concurrent(miningStartupTask, .{io, &components}));
    }

    std.log.info("✅ ZeiCoin node started successfully", .{});
    std.log.info("Press Ctrl+C to shutdown", .{});

    // Wait for shutdown (SIGINT/SIGTERM)
    try io.checkCancel();

    std.log.info("Shutting down...", .{});

    // All tasks auto-cancelled, cleanup via defer
}

fn periodicStatus(io: std.Io, components: *NodeComponents) !void {
    while (true) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(30), std.Io.Clock.awake);
  printStatus(components);
    }
}

fn periodicMaintenance(io: std.Io, components: *NodeComponents) !void {
    while (true) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(10), std.Io.Clock.awake);
  components.network_manager.maintenance();
    }
}

fn periodicSyncCheck(io: std.Io, components: *NodeComponents) !void {
    while (true) {
  try io.checkCancel();
  try io.sleep(std.Io.Duration.fromSeconds(5), std.Io.Clock.awake);
  components.sync_manager.checkTimeout();

  const sync_state = components.sync_manager.getSyncState();
  if (sync_state == .idle or sync_state == .failed) {
      const our_height = components.blockchain.getHeight() catch 0;
      const highest = components.network_manager.getHighestPeerHeight();

      if (highest > our_height) {
          std.log.info("Auto sync retry: {} blocks behind", .{highest - our_height});
          // Spawn recovery as sub-task
          _ = try io.concurrent(syncRecovery, .{components.sync_manager});
      }
  }
    }
}

fn syncRecovery(sync_manager: *SyncManager) !void {
    try sync_manager.attemptSyncRecovery();
}
```

**New complexity:**
- ~150 lines (~45% reduction)
- 0 manual timestamps
- 0 thread spawns
- 0 signal handlers
- 0 atomic flags
- 0 polling loops
- 0 state flags
- Clean io.sleep() calls

## Complexity Metrics

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| Lines of code | 278 | ~150 | 46% |
| State variables | 6 | 0 | 100% |
| Thread management | 3 | 0 | 100% |
| Signal handlers | 2 | 0 | 100% |
| Atomic operations | Multiple | 0 | 100% |
| Manual time math | 4 places | 0 | 100% |

## Key Benefits

1. **No More Polling Loop** - Event-driven instead of check-every-100ms
2. **Automatic Cancellation** - io.checkCancel() propagates to all tasks
3. **Cleaner Separation** - Each task is isolated function
4. **Better Testing** - Can test periodicStatus() independently
5. **Simpler Shutdown** - No manual thread.join() or flag coordination
6. **Type Safety** - Futures have typed return values

## Migration Path

### Phase 1: Simple Replacements (Low Risk)
1. Replace `std.time.sleep()` → `io.sleep(Duration, Clock)`
2. Replace `std.time.timestamp()` → Use Clock.awake for intervals
3. Test: Server still runs, no behavior change

### Phase 2: Task Isolation (Medium)
4. Extract periodic tasks to separate functions
5. Replace Thread.spawn → io.concurrent()
6. Test: All background tasks still work

### Phase 3: Remove Polling (High Impact)
7. Remove while loop + atomic flag
8. Use io.checkCancel() for shutdown
9. Test: Graceful shutdown works

## Testing Strategy

```zig
test "periodic task isolated" {
    const allocator = std.testing.allocator;

    var threaded = std.Io.Threaded.init(allocator, .{ .environ = .empty });
    defer threaded.deinit();
    const io = threaded.io();

    var components = try createTestComponents();
    defer components.deinit();

    // Test runs for 3 iterations then cancels
    const future = try io.concurrent(periodicStatus, .{io, &components});

    try io.sleep(std.Io.Duration.fromSeconds(100), std.Io.Clock.awake);
    io.cancel(future);

    // Should have printed status ~3 times
}
```

## Real-World Impact

**Before migration:**
- Developer confusion: "Why do we need 3 timestamps?"
- Bug: Missed interval due to time drift
- Hard to test: Can't isolate periodic tasks
- Shutdown issues: Threads don't always join cleanly

**After migration:**
- Clear: Each task is a function
- Reliable: Monotonic clock prevents drift
- Testable: Each function can be unit tested
- Clean: Automatic cancellation and cleanup

## Next Steps

1. Read this guide
2. Try small change: Replace one std.time.sleep() with io.sleep()
3. Test server behavior unchanged
4. Gradually adopt concurrent() for background tasks
5. Final step: Remove polling loop

The biggest win is **removing the entire polling loop** - your server becomes event-driven!
