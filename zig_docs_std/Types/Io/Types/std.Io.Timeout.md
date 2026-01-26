# std.Io.Timeout

Declares under what conditions an operation should return `error.Timeout`.

### Fields

    none

    duration: Clock.Duration

    deadline: Clock.Timestamp

## Functions

`pub fn sleep(timeout: Timeout, io: Io) SleepError!void`  

`pub fn toDeadline(t: Timeout, io: Io) Clock.Error!?Clock.Timestamp`  

`pub fn toDurationFromNow(t: Timeout, io: Io) Clock.Error!?Clock.Duration`  

## Error Sets

- Error
