# std.process.RunOptions

### Fields

    argv: []const []const u8

    stderr_limit: Io.Limit = .unlimited

    stdout_limit: Io.Limit = .unlimited

    reserve_amount: usize = 64

How many bytes to initially allocate for stderr and stdout.

    cwd: Child.Cwd = .inherit

Set to change the current working directory when spawning the child process.

    environ_map: ?*const Environ.Map = null

Replaces the child environment when provided. The PATH value from here is not used to resolve `argv[0]`; that resolution always uses parent environment.

    expand_arg0: ArgExpansion = .no_expand

    progress_node: std.Progress.Node = std.Progress.Node.none

When populated, a pipe will be created for the child process to communicate progress back to the parent. The file descriptor of the write end of the pipe will be specified in the `ZIG_PROGRESS` environment variable inside the child process. The progress reported by the child will be attached to this progress node in the parent process.

The child's progress tree will be grafted into the parent's progress tree, by substituting this node with the child's root node.

    create_no_window: bool = true

Windows-only. Sets the CREATE_NO_WINDOW flag in CreateProcess.

    disable_aslr: bool = false

Darwin-only. Disable ASLR for the child process.

    timeout: Io.Timeout = .none
