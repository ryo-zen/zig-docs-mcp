# std.Io.net.OutgoingMessage

### Fields

    address: *const IpAddress

    data_ptr: [*]const u8

    data_len: usize

Initialized with how many bytes of `data_ptr` to send. After sending succeeds, replaced with how many bytes were actually sent.

    control: []const u8 = &.{}
