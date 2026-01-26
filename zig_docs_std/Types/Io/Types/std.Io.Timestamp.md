# std.Io.Timestamp

### Fields

    nanoseconds: i96

## Values

|      |             |     |
|------|-------------|-----|
| zero | `Timestamp` |     |

## Functions

`pub fn addDuration(from: Timestamp, duration: Duration) Timestamp`  

`pub fn durationTo(from: Timestamp, to: Timestamp) Duration`  

`pub fn formatNumber(t: Timestamp, w: *std.Io.Writer, n: std.fmt.Number) std.Io.Writer.Error!void`  

`pub fn fromNanoseconds(x: i96) Timestamp`  

`pub fn subDuration(from: Timestamp, duration: Duration) Timestamp`  

`pub fn toMilliseconds(t: Timestamp) i64`  

`pub fn toNanoseconds(t: Timestamp) i96`  

`pub fn toSeconds(t: Timestamp) i64`  

`pub fn withClock(t: Timestamp, clock: Clock) Clock.Timestamp`  
