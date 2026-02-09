# std.process.SpawnOptions

### Fields

    argv: []const []const u8

    cwd: Child.Cwd = .inherit

Set to change the current working directory when spawning the child process.

    environ_map: ?*const Environ.Map = null

Replaces the child environment when provided. The PATH value from here is not used to resolve `argv[0]`; that resolution always uses parent environment.

    expand_arg0: ArgExpansion = .no_expand

    progress_node: std.Progress.Node = std.Progress.Node.none

When populated, a pipe will be created for the child process to communicate progress back to the parent. The file descriptor of the write end of the pipe will be specified in the `ZIG_PROGRESS` environment variable inside the child process. The progress reported by the child will be attached to this progress node in the parent process.

The child's progress tree will be grafted into the parent's progress tree, by substituting this node with the child's root node.

    stdin: StdIo = .inherit

    stdout: StdIo = .inherit

    stderr: StdIo = .inherit

    request_resource_usage_statistics: bool = false

Set to true to obtain rusage information for the child process. Depending on the target platform and implementation status, the requested statistics may or may not be available. If they are available, then the `resource_usage_statistics` field will be populated after calling `wait`. On Linux and Darwin, this obtains rusage statistics from wait4().

    uid: ?posix.uid_t = null

Set to change the user id when spawning the child process.

    gid: ?posix.gid_t = null

Set to change the group id when spawning the child process.

    pgid: ?posix.pid_t = null

Set to change the process group id when spawning the child process.

    start_suspended: bool = false

Start child process in suspended state. For Posix systems it's started as if SIGSTOP was sent.

    create_no_window: bool = false

Windows-only. Sets the CREATE_NO_WINDOW flag in CreateProcess.

    disable_aslr: bool = false

Darwin-only. Disable ASLR for the child process.

## Types

- StdIo
