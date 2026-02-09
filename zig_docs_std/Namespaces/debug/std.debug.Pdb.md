# std.debug.Pdb

### Fields

    file_reader: *File.Reader

    msf: Msf

    allocator: Allocator

    string_table: ?*MsfStream

    dbi: ?*MsfStream

    modules: []Module

    sect_contribs: []pdb.SectionContribEntry

    guid: [16]u8

    age: u32

## Types

- Module

## Functions

`pub fn deinit(self: *Pdb) void`  

`pub fn getLineNumberInfo(self: *Pdb, module: *Module, address: u64) !std.debug.SourceLocation`  

`pub fn getModule(self: *Pdb, index: usize) !?*Module`  

`pub fn getStream(self: *Pdb, stream: pdb.StreamType) ?*MsfStream`  

`pub fn getStreamById(self: *Pdb, id: u32) ?*MsfStream`  

`pub fn getSymbolName(self: *Pdb, module: *Module, address: u64) ?[]const u8`  

`pub fn init(gpa: Allocator, file_reader: *File.Reader) !Pdb`  

`pub fn parseDbiStream(self: *Pdb) !void`  

`pub fn parseInfoStream(self: *Pdb) !void`  
