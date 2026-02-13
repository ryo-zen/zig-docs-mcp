# std.debug.Pdb

## Overview

`std.debug.Pdb` handles Program Database (PDB) debug data on Windows/COFF workflows.

It parses key PDB streams and exposes module/symbol/source-location lookup helpers.

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
Releases PDB-owned parsed data and stream resources.

`pub fn getLineNumberInfo(self: *Pdb, module: *Module, address: u64) !std.debug.SourceLocation`
Resolves an address to source file/line/column within a module.

`pub fn getModule(self: *Pdb, index: usize) !?*Module`
Returns a module by index when present.

`pub fn getStream(self: *Pdb, stream: pdb.StreamType) ?*MsfStream`
Returns a well-known stream by typed identifier.

`pub fn getStreamById(self: *Pdb, id: u32) ?*MsfStream`
Returns a stream by raw stream ID.

`pub fn getSymbolName(self: *Pdb, module: *Module, address: u64) ?[]const u8`
Looks up a symbol name for an address.

`pub fn init(gpa: Allocator, file_reader: *File.Reader) !Pdb`
Initializes a PDB reader state from an input file reader.

`pub fn parseDbiStream(self: *Pdb) !void`
Parses DBI stream data (module/symbol index metadata).

`pub fn parseInfoStream(self: *Pdb) !void`
Parses PDB info stream metadata.

## Usage Notes

- Typical flow: `init` -> parse info/DBI streams -> module/symbol lookups -> `deinit`.
- Some methods require a valid `Module` reference from `getModule`.
- Missing line/symbol info is common in partially stripped debug builds.
