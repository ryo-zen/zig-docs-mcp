# std.Io.VTable

### Fields

    async: *const fn (
  /// Corresponds to `Io.userdata`.
  userdata: ?*anyopaque,
  /// The pointer of this slice is an "eager" result value.
  /// The length is the size in bytes of the result type.
  /// This pointer's lifetime expires directly after the call to this function.
  result: []u8,
  result_alignment: std.mem.Alignment,
  /// Copied and then passed to `start`.
  context: []const u8,
  context_alignment: std.mem.Alignment,
  start: *const fn (context: *const anyopaque, result: *anyopaque) void,
    ) ?*AnyFuture

If it returns `null` it means `result` has been already populated and `await` will be a no-op.

When this function returns non-null, the implementation guarantees that a unit of concurrency has been assigned to the returned task.

Thread-safe.

    concurrent: *const fn (
  /// Corresponds to `Io.userdata`.
  userdata: ?*anyopaque,
  result_len: usize,
  result_alignment: std.mem.Alignment,
  /// Copied and then passed to `start`.
  context: []const u8,
  context_alignment: std.mem.Alignment,
  start: *const fn (context: *const anyopaque, result: *anyopaque) void,
    ) ConcurrentError!*AnyFuture

Thread-safe.

    await: *const fn (
  /// Corresponds to `Io.userdata`.
  userdata: ?*anyopaque,
  /// The same value that was returned from `async`.
  any_future: *AnyFuture,
  /// Points to a buffer where the result is written.
  /// The length is equal to size in bytes of result type.
  result: []u8,
  result_alignment: std.mem.Alignment,
    ) void

This function is only called when `async` returns a non-null value.

Thread-safe.

    cancel: *const fn (
  /// Corresponds to `Io.userdata`.
  userdata: ?*anyopaque,
  /// The same value that was returned from `async`.
  any_future: *AnyFuture,
  /// Points to a buffer where the result is written.
  /// The length is equal to size in bytes of result type.
  result: []u8,
  result_alignment: std.mem.Alignment,
    ) void

Equivalent to `await` but initiates cancel request.

This function is only called when `async` returns a non-null value.

Thread-safe.

    groupAsync: *const fn (
  /// Corresponds to `Io.userdata`.
  userdata: ?*anyopaque,
  /// Owner of the spawned async task.
  group: *Group,
  /// Copied and then passed to `start`.
  context: []const u8,
  context_alignment: std.mem.Alignment,
  start: *const fn (context: *const anyopaque) Cancelable!void,
    ) void

When this function returns, implementation guarantees that `start` has either already been called, or a unit of concurrency has been assigned to the task of calling the function.

Thread-safe.

    groupConcurrent: *const fn (
  /// Corresponds to `Io.userdata`.
  userdata: ?*anyopaque,
  /// Owner of the spawned async task.
  group: *Group,
  /// Copied and then passed to `start`.
  context: []const u8,
  context_alignment: std.mem.Alignment,
  start: *const fn (context: *const anyopaque) Cancelable!void,
    ) ConcurrentError!void

Thread-safe.

    groupAwait: *const fn (?*anyopaque, *Group, token: *anyopaque) Cancelable!void

    groupCancel: *const fn (?*anyopaque, *Group, token: *anyopaque) void

    recancel: *const fn (?*anyopaque) void

    swapCancelProtection: *const fn (?*anyopaque, new: CancelProtection) CancelProtection

    checkCancel: *const fn (?*anyopaque) Cancelable!void

    select: *const fn (?*anyopaque, futures: []const *AnyFuture) Cancelable!usize

Blocks until one of the futures from the list has a result ready, such that awaiting it will not block. Returns that index.

    futexWait: *const fn (?*anyopaque, ptr: *const u32, expected: u32, Timeout) Cancelable!void

    futexWaitUncancelable: *const fn (?*anyopaque, ptr: *const u32, expected: u32) void

    futexWake: *const fn (?*anyopaque, ptr: *const u32, max_waiters: u32) void

    dirCreateDir: *const fn (?*anyopaque, Dir, []const u8, Dir.Permissions) Dir.CreateDirError!void

    dirCreateDirPath: *const fn (?*anyopaque, Dir, []const u8, Dir.Permissions) Dir.CreateDirPathError!Dir.CreatePathStatus

    dirCreateDirPathOpen: *const fn (?*anyopaque, Dir, []const u8, Dir.Permissions, Dir.OpenOptions) Dir.CreateDirPathOpenError!Dir

    dirOpenDir: *const fn (?*anyopaque, Dir, []const u8, Dir.OpenOptions) Dir.OpenError!Dir

    dirStat: *const fn (?*anyopaque, Dir) Dir.StatError!Dir.Stat

    dirStatFile: *const fn (?*anyopaque, Dir, []const u8, Dir.StatFileOptions) Dir.StatFileError!File.Stat

    dirAccess: *const fn (?*anyopaque, Dir, []const u8, Dir.AccessOptions) Dir.AccessError!void

    dirCreateFile: *const fn (?*anyopaque, Dir, []const u8, File.CreateFlags) File.OpenError!File

    dirCreateFileAtomic: *const fn (?*anyopaque, Dir, []const u8, Dir.CreateFileAtomicOptions) Dir.CreateFileAtomicError!File.Atomic

    dirOpenFile: *const fn (?*anyopaque, Dir, []const u8, File.OpenFlags) File.OpenError!File

    dirClose: *const fn (?*anyopaque, []const Dir) void

    dirRead: *const fn (?*anyopaque, *Dir.Reader, []Dir.Entry) Dir.Reader.Error!usize

    dirRealPath: *const fn (?*anyopaque, Dir, out_buffer: []u8) Dir.RealPathError!usize

    dirRealPathFile: *const fn (?*anyopaque, Dir, path_name: []const u8, out_buffer: []u8) Dir.RealPathFileError!usize

    dirDeleteFile: *const fn (?*anyopaque, Dir, []const u8) Dir.DeleteFileError!void

    dirDeleteDir: *const fn (?*anyopaque, Dir, []const u8) Dir.DeleteDirError!void

    dirRename: *const fn (?*anyopaque, old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8) Dir.RenameError!void

    dirRenamePreserve: *const fn (?*anyopaque, old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8) Dir.RenamePreserveError!void

    dirSymLink: *const fn (?*anyopaque, Dir, target_path: []const u8, sym_link_path: []const u8, Dir.SymLinkFlags) Dir.SymLinkError!void

    dirReadLink: *const fn (?*anyopaque, Dir, sub_path: []const u8, buffer: []u8) Dir.ReadLinkError!usize

    dirSetOwner: *const fn (?*anyopaque, Dir, ?File.Uid, ?File.Gid) Dir.SetOwnerError!void

    dirSetFileOwner: *const fn (?*anyopaque, Dir, []const u8, ?File.Uid, ?File.Gid, Dir.SetFileOwnerOptions) Dir.SetFileOwnerError!void

    dirSetPermissions: *const fn (?*anyopaque, Dir, Dir.Permissions) Dir.SetPermissionsError!void

    dirSetFilePermissions: *const fn (?*anyopaque, Dir, []const u8, File.Permissions, Dir.SetFilePermissionsOptions) Dir.SetFilePermissionsError!void

    dirSetTimestamps: *const fn (?*anyopaque, Dir, []const u8, Dir.SetTimestampsOptions) Dir.SetTimestampsError!void

    dirHardLink: *const fn (?*anyopaque, old_dir: Dir, old_sub_path: []const u8, new_dir: Dir, new_sub_path: []const u8, Dir.HardLinkOptions) Dir.HardLinkError!void

    fileStat: *const fn (?*anyopaque, File) File.StatError!File.Stat

    fileLength: *const fn (?*anyopaque, File) File.LengthError!u64

    fileClose: *const fn (?*anyopaque, []const File) void

    fileWriteStreaming: *const fn (?*anyopaque, File, header: []const u8, data: []const []const u8, splat: usize) File.Writer.Error!usize

    fileWritePositional: *const fn (?*anyopaque, File, header: []const u8, data: []const []const u8, splat: usize, offset: u64) File.WritePositionalError!usize

    fileWriteFileStreaming: *const fn (?*anyopaque, File, header: []const u8, *Io.File.Reader, Io.Limit) File.Writer.WriteFileError!usize

    fileWriteFilePositional: *const fn (?*anyopaque, File, header: []const u8, *Io.File.Reader, Io.Limit, offset: u64) File.WriteFilePositionalError!usize

    fileReadStreaming: *const fn (?*anyopaque, File, data: []const []u8) File.Reader.Error!usize

Returns 0 on end of stream.

    fileReadPositional: *const fn (?*anyopaque, File, data: []const []u8, offset: u64) File.ReadPositionalError!usize

Returns 0 on end of stream.

    fileSeekBy: *const fn (?*anyopaque, File, relative_offset: i64) File.SeekError!void

    fileSeekTo: *const fn (?*anyopaque, File, absolute_offset: u64) File.SeekError!void

    fileSync: *const fn (?*anyopaque, File) File.SyncError!void

    fileIsTty: *const fn (?*anyopaque, File) Cancelable!bool

    fileEnableAnsiEscapeCodes: *const fn (?*anyopaque, File) File.EnableAnsiEscapeCodesError!void

    fileSupportsAnsiEscapeCodes: *const fn (?*anyopaque, File) Cancelable!bool

    fileSetLength: *const fn (?*anyopaque, File, u64) File.SetLengthError!void

    fileSetOwner: *const fn (?*anyopaque, File, ?File.Uid, ?File.Gid) File.SetOwnerError!void

    fileSetPermissions: *const fn (?*anyopaque, File, File.Permissions) File.SetPermissionsError!void

    fileSetTimestamps: *const fn (?*anyopaque, File, File.SetTimestampsOptions) File.SetTimestampsError!void

    fileLock: *const fn (?*anyopaque, File, File.Lock) File.LockError!void

    fileTryLock: *const fn (?*anyopaque, File, File.Lock) File.LockError!bool

    fileUnlock: *const fn (?*anyopaque, File) void

    fileDowngradeLock: *const fn (?*anyopaque, File) File.DowngradeLockError!void

    fileRealPath: *const fn (?*anyopaque, File, out_buffer: []u8) File.RealPathError!usize

    fileHardLink: *const fn (?*anyopaque, File, Dir, []const u8, File.HardLinkOptions) File.HardLinkError!void

    fileMemoryMapCreate: *const fn (?*anyopaque, File, File.MemoryMap.CreateOptions) File.MemoryMap.CreateError!File.MemoryMap

    fileMemoryMapDestroy: *const fn (?*anyopaque, *File.MemoryMap) void

    fileMemoryMapSetLength: *const fn (?*anyopaque, *File.MemoryMap, File.MemoryMap.CreateOptions) File.MemoryMap.SetLengthError!void

    fileMemoryMapRead: *const fn (?*anyopaque, *File.MemoryMap) File.ReadPositionalError!void

    fileMemoryMapWrite: *const fn (?*anyopaque, *File.MemoryMap) File.WritePositionalError!void

    processExecutableOpen: *const fn (?*anyopaque, File.OpenFlags) std.process.OpenExecutableError!File

    processExecutablePath: *const fn (?*anyopaque, buffer: []u8) std.process.ExecutablePathError!usize

    lockStderr: *const fn (?*anyopaque, ?Terminal.Mode) Cancelable!LockedStderr

    tryLockStderr: *const fn (?*anyopaque, ?Terminal.Mode) Cancelable!?LockedStderr

    unlockStderr: *const fn (?*anyopaque) void

    processSetCurrentDir: *const fn (?*anyopaque, Dir) std.process.SetCurrentDirError!void

    processReplace: *const fn (?*anyopaque, std.process.ReplaceOptions) std.process.ReplaceError

    processReplacePath: *const fn (?*anyopaque, Dir, std.process.ReplaceOptions) std.process.ReplaceError

    processSpawn: *const fn (?*anyopaque, std.process.SpawnOptions) std.process.SpawnError!std.process.Child

    processSpawnPath: *const fn (?*anyopaque, Dir, std.process.SpawnOptions) std.process.SpawnError!std.process.Child

    childWait: *const fn (?*anyopaque, *std.process.Child) std.process.Child.WaitError!std.process.Child.Term

    childKill: *const fn (?*anyopaque, *std.process.Child) void

    progressParentFile: *const fn (?*anyopaque) std.Progress.ParentFileError!File

    now: *const fn (?*anyopaque, Clock) Clock.Error!Timestamp

    sleep: *const fn (?*anyopaque, Timeout) SleepError!void

    random: *const fn (?*anyopaque, buffer: []u8) void

    randomSecure: *const fn (?*anyopaque, buffer: []u8) RandomSecureError!void

    netListenIp: *const fn (?*anyopaque, address: net.IpAddress, net.IpAddress.ListenOptions) net.IpAddress.ListenError!net.Server

    netAccept: *const fn (?*anyopaque, server: net.Socket.Handle) net.Server.AcceptError!net.Stream

    netBindIp: *const fn (?*anyopaque, address: *const net.IpAddress, options: net.IpAddress.BindOptions) net.IpAddress.BindError!net.Socket

    netConnectIp: *const fn (?*anyopaque, address: *const net.IpAddress, options: net.IpAddress.ConnectOptions) net.IpAddress.ConnectError!net.Stream

    netListenUnix: *const fn (?*anyopaque, *const net.UnixAddress, net.UnixAddress.ListenOptions) net.UnixAddress.ListenError!net.Socket.Handle

    netConnectUnix: *const fn (?*anyopaque, *const net.UnixAddress) net.UnixAddress.ConnectError!net.Socket.Handle

    netSend: *const fn (?*anyopaque, net.Socket.Handle, []net.OutgoingMessage, net.SendFlags) struct { ?net.Socket.SendError, usize }

    netReceive: *const fn (?*anyopaque, net.Socket.Handle, message_buffer: []net.IncomingMessage, data_buffer: []u8, net.ReceiveFlags, Timeout) struct { ?net.Socket.ReceiveTimeoutError, usize }

    netRead: *const fn (?*anyopaque, src: net.Socket.Handle, data: [][]u8) net.Stream.Reader.Error!usize

Returns 0 on end of stream.

    netWrite: *const fn (?*anyopaque, dest: net.Socket.Handle, header: []const u8, data: []const []const u8, splat: usize) net.Stream.Writer.Error!usize

    netWriteFile: *const fn (?*anyopaque, net.Socket.Handle, header: []const u8, *Io.File.Reader, Io.Limit) net.Stream.Writer.WriteFileError!usize

    netClose: *const fn (?*anyopaque, handle: []const net.Socket.Handle) void

    netShutdown: *const fn (?*anyopaque, handle: net.Socket.Handle, how: net.ShutdownHow) net.ShutdownError!void

    netInterfaceNameResolve: *const fn (?*anyopaque, *const net.Interface.Name) net.Interface.Name.ResolveError!net.Interface

    netInterfaceName: *const fn (?*anyopaque, net.Interface) net.Interface.NameError!net.Interface.Name

    netLookup: *const fn (?*anyopaque, net.HostName, *Queue(net.HostName.LookupResult), net.HostName.LookupOptions) net.HostName.LookupError!void
