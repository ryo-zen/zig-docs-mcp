# std.http

## Overview

`std.http` contains HTTP protocol types, parsers, body readers/writers, and client/server entry points.

Source: `/path/to/zig-0.16.0/lib/std/http.zig`

## Public API

### Major Types

- `std.http.Client` - HTTP client implementation from `http/Client.zig`.
- `std.http.Server` - HTTP server implementation from `http/Server.zig`.
- `std.http.HeadParser` - parser for HTTP head sections.
- `std.http.ChunkParser` - parser for chunked transfer encoding.
- `std.http.HeaderIterator` - helper for iterating headers.
- `std.http.Reader` - body reader helper.
- `std.http.BodyWriter` - body writer helper.

### Protocol Enums

- `std.http.Version` - `.@"HTTP/1.0"` or `.@"HTTP/1.1"`.
- `std.http.Method` - HTTP methods: `GET`, `HEAD`, `POST`, `PUT`, `DELETE`, `CONNECT`, `OPTIONS`, `TRACE`, and `PATCH`.
- `std.http.Status` - HTTP status codes represented as an enum with integer tag type `u10`.
- `std.http.TransferEncoding` - transfer-encoding mode.
- `std.http.ContentEncoding` - content-encoding mode.
- `std.http.Connection` - connection behavior.
- `std.http.Decompress` - decompression mode for encoded bodies.

### Header Representation

- `std.http.Header` - a header pair with `name` and `value` slices.

## Method Helpers

`std.http.Method` exposes protocol classification helpers:

- `requestHasBody()` - whether the request method is allowed to carry a body.
- `responseHasBody()` - whether a response to the method is allowed to carry a body.
- `safe()` - whether the method is considered safe.
- `idempotent()` - whether repeating the same request should have the same effect.
- `cacheable()` - whether responses to the method are cacheable by default.

## Status Helpers

`std.http.Status.phrase()` returns the standard reason phrase for known status codes and `null` for unknown extension values.

## Notes

`std.http` is the protocol-level namespace. Networking and file descriptor behavior are provided by lower-level I/O, OS, and POSIX facilities.
