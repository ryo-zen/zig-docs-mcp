# std.Io.Threaded

### Fields

    allocator: Allocator

Thread-safe.

Used for:

- allocating `Io.Future` and `Io.Group` closures.
- formatting spawning child processes
- scanning environment variables on some targets
- memory-mapping when mmap or equivalent is not available

<!-- -->

    mutex: std.Thread.Mutex = .{}

    cond: std.Thread.Condition = .{}

    run_queue: std.SinglyLinkedList = .{}

    join_requested: bool = false

    stack_size: usize

    wait_group: std.Thread.WaitGroup = .{}

All threads are spawned detached; this is how we wait until they all exit.

    async_limit: Io.Limit

    concurrent_limit: Io.Limit = .unlimited

    cpu_count_error: ?std.Thread.CpuCountError

Error from calling `std.Thread.getCpuCount` in `init`.

    busy_count: usize = 0

Number of threads that are unavailable to take tasks. To calculate available count, subtract this from either `async_limit` or `concurrent_limit`.

    worker_threads: std.atomic.Value(?*Thread)

    pid: Pid = .unknown

    wsa: if (is_windows) Wsa else struct {} = .{}

    have_signal_handler: bool

    old_sig_io: if (have_sig_io) posix.Sigaction else void

    old_sig_pipe: if (have_sig_pipe) posix.Sigaction else void

    use_sendfile: UseSendfile = .default

    use_copy_file_range: UseCopyFileRange = .default

    use_fcopyfile: UseFcopyfile = .default

    use_fchmodat2: UseFchmodat2 = .default

    disable_memory_mapping: bool

    stderr_writer: File.Writer = .{
        .io = undefined,
        .interface = Io.File.Writer.initInterface(&.{}),
        .file = if (is_windows) undefined else .stderr(),
        .mode = .streaming,
    }

    stderr_mode: Io.Terminal.Mode = .no_color

    stderr_writer_initialized: bool = false

    argv0: Argv0

    environ: Environ

    null_file: NullFile = .{}

    random_file: RandomFile = .{}

    csprng: Csprng = .{}

    system_basic_information: SystemBasicInformation = .{}

## Types

- Argv0
- Csprng
- InitOptions
- NullFile
- Pid
- PosixAddress
- RandomFile
- UseCopyFileRange
- UseFchmodat2
- UseFcopyfile
- UseSendfile

## Values

|  |  |  |
|----|----|----|
| global_single_threaded | `*Threaded` | In general, the application is responsible for choosing the `Io` implementation and library code should accept an `Io` parameter rather than accessing this declaration. Most code should avoid referencing this declaration entirely. |
| init_single_threaded | `Threaded` | Statically initialize such that calls to `Io.VTable.concurrent` will fail with `error.ConcurrencyUnavailable`. |
| socket_flags_unsupported |  |  |

## Functions

`pub fn addressFromPosix(posix_address: *const PosixAddress) IpAddress`  

`pub fn addressToPosix(a: *const IpAddress, storage: *PosixAddress) posix.socklen_t`  

`pub fn chdir(dir_path: []const u8) ChdirError!void`  

`pub fn deinit(t: *Threaded) void`  

`pub fn dirOpenDirWindows( dir: Dir, sub_path_w: [:0]const u16, options: Dir.OpenOptions, ) Dir.OpenError!Dir`  

`pub fn dirOpenFileWtf16( dir_handle: ?windows.HANDLE, sub_path_w: [:0]const u16, flags: File.OpenFlags, ) File.OpenError!File`  

`pub fn dup2(old_fd: posix.fd_t, new_fd: posix.fd_t) DupError!void`  

`pub fn environString(t: *Threaded, comptime name: []const u8) ?[:0]const u8`  

`pub fn errnoBug(err: posix.E) Io.UnexpectedError`  

`pub fn fchdir(fd: posix.fd_t) FchdirError!void`  

`pub fn init( gpa: Allocator, options: InitOptions, ) Threaded`  
Related:

- `init_single_threaded`

`pub fn io(t: *Threaded) Io`  

`pub fn ioBasic(t: *Threaded) Io`  
Same as `io` but disables all networking functionality, which has an additional dependency on Windows (ws2_32).

`pub fn pipe2(flags: posix.O) PipeError![2]posix.fd_t`  

`pub fn posixAddressFamily(a: *const IpAddress) posix.sa_family_t`  

`pub fn posixExecvPath( path: [*:0]const u8, child_argv: [*:null]const ?[*:0]const u8, envp: [*:null]const ?[*:0]const u8, ) process.ReplaceError`  
This function ignores PATH environment variable.

`pub fn posixProtocol(protocol: ?net.Protocol) u32`  

`pub fn posixSocketMode(mode: net.Socket.Mode) u32`  

`pub fn setAsyncLimit(t: *Threaded, new_limit: Io.Limit) void`  

## Error Sets

- ChdirError
- DupError
- FchdirError
- PipeError
