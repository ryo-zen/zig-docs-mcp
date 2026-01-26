# std.Io.net.HostName

An already-validated host name. A valid host name:

- Has length less than or equal to `max_len`.
- Is valid UTF-8.
- Lacks ASCII characters other than alphanumeric, '-', and '.'.

### Fields

    bytes: []const u8

Externally managed memory. Already checked to be valid.

## Types

- DnsRecord
- DnsResponse
- LookupOptions
- LookupResult
- ResolvConf

## Values

|         |     |     |
|---------|-----|-----|
| max_len |     |     |

## Functions

`pub fn connect( host_name: HostName, io: Io, port: u16, options: IpAddress.ConnectOptions, ) ConnectError!Stream`  

`pub fn connectMany( host_name: HostName, io: Io, port: u16, results: *Io.Queue(IpAddress.ConnectError!Stream), options: IpAddress.ConnectOptions, ) LookupError!void`  
Asynchronously establishes a connection to all IP addresses associated with a host name, adding them to a results queue upon completion.

`pub fn eql(a: HostName, b: HostName) bool`  
Domain names are case-insensitive (RFC 5890, Section 2.3.2.4)

`pub fn expand(noalias packet: []const u8, start_i: usize, noalias dest_buffer: []u8) ExpandError!struct { usize, HostName }`  
Decompresses a DNS name.

`pub fn init(bytes: []const u8) ValidateError!HostName`  

`pub fn lookup( host_name: HostName, io: Io, resolved: *Io.Queue(LookupResult), options: LookupOptions, ) LookupError!void`  
Adds any number of `LookupResult.address` into `resolved`, and exactly one `LookupResult.canonical_name`.

`pub fn sameParentDomain(parent_host: HostName, child_host: HostName) bool`  

`pub fn validate(bytes: []const u8) ValidateError!void`  
Validates a hostname according to RFC 1123

## Error Sets

- ConnectError
- ExpandError
- LookupError
- ValidateError
