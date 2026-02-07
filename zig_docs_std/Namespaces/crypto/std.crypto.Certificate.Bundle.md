# std.crypto.Certificate.Bundle

A set of certificates. Typically pre-installed on every operating system, these are "Certificate Authorities" used to validate SSL certificates. This data structure stores certificates in DER-encoded form, all of them concatenated together in the `bytes` array. The `map` field contains an index from the DER-encoded subject name to the index of the containing certificate within `bytes`.

### Fields

    map: std.HashMapUnmanaged(der.Element.Slice, u32, MapContext, std.hash_map.default_max_load_percentage) = .empty

The key is the contents slice of the subject.

    bytes: std.ArrayList(u8) = .empty

## Functions

`pub fn addCertsFromDir(cb: *Bundle, gpa: Allocator, io: Io, now: Io.Timestamp, iterable_dir: Io.Dir) AddCertsFromDirError!void`  

`pub fn addCertsFromDirPath( cb: *Bundle, gpa: Allocator, io: Io, dir: Io.Dir, sub_dir_path: []const u8, ) AddCertsFromDirPathError!void`  

`pub fn addCertsFromDirPathAbsolute( cb: *Bundle, gpa: Allocator, io: Io, now: Io.Timestamp, abs_dir_path: []const u8, ) AddCertsFromDirPathError!void`  

`pub fn addCertsFromFile(cb: *Bundle, gpa: Allocator, file_reader: *Io.File.Reader, now_sec: i64) AddCertsFromFileError!void`  

`pub fn addCertsFromFilePath( cb: *Bundle, gpa: Allocator, io: Io, now: Io.Timestamp, dir: Io.Dir, sub_file_path: []const u8, ) AddCertsFromFilePathError!void`  

`pub fn addCertsFromFilePathAbsolute( cb: *Bundle, gpa: Allocator, io: Io, now: Io.Timestamp, abs_file_path: []const u8, ) AddCertsFromFilePathError!void`  

`pub fn deinit(cb: *Bundle, gpa: Allocator) void`  

`pub fn find(cb: Bundle, subject_name: []const u8) ?u32`  
The returned bytes become invalid after calling any of the rescan functions or add functions.

`pub fn parseCert(cb: *Bundle, gpa: Allocator, decoded_start: u32, now_sec: i64) ParseCertError!void`  

`pub fn rescan(cb: *Bundle, gpa: Allocator, io: Io, now: Io.Timestamp) RescanError!void`  
Clears the set of certificates and then scans the host operating system file system standard locations for certificates. For operating systems that do not have standard CA installations to be found, this function clears the set of certificates.

`pub fn verify(cb: Bundle, subject: Certificate.Parsed, now_sec: i64) VerifyError!void`  

## Error Sets

- AddCertsFromDirError
- AddCertsFromDirPathError
- AddCertsFromFileError
- AddCertsFromFilePathError
- ParseCertError
- RescanError
- VerifyError
