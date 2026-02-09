# std.process.Child

### Fields

    id: ?Id

After `wait` or `kill` is called, this becomes `null`. On Windows this is the hProcess. On POSIX this is the pid.

    thread_handle: if (native_os == .windows) std.os.windows.HANDLE else void

    stdin: ?File

The writing end of the child process's standard input pipe. Usage requires `process.SpawnOptions.StdIo.pipe`.

    stdout: ?File

The reading end of the child process's standard output pipe. Usage requires `process.SpawnOptions.StdIo.pipe`.

    stderr: ?File

The reading end of the child process's standard error pipe. Usage requires `process.SpawnOptions.StdIo.pipe`.

    resource_usage_statistics: ResourceUsageStatistics = .{}

This is available after calling wait if `request_resource_usage_statistics` was set to `true` before calling `spawn`. TODO move this data into `Term`

    request_resource_usage_statistics: bool

## Types

- Cwd
- Id
- ResourceUsageStatistics
- Term

## Functions

`pub fn kill(child: *Child, io: Io) void`  
Requests for the operating system to forcibly terminate the child process, then blocks until it terminates, then cleans up all resources.

`pub fn wait(child: *Child, io: Io) WaitError!Term`  
Blocks until child process terminates and then cleans up all resources.

## Error Sets

- WaitError
