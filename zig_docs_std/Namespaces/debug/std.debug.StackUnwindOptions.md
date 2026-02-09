# std.debug.StackUnwindOptions

### Fields

    first_address: ?usize = null

If not `null`, we will ignore all frames up until this return address. This is typically used to omit intermediate handling code (for instance, a panic handler and its machinery) from stack traces.

    context: ?CpuContextPtr = null

If not `null`, we will unwind from this `cpu_context.Native` instead of the current top of the stack. The main use case here is printing stack traces from signal handlers, where the kernel provides a `*const cpu_context.Native` of the state before the signal.

    allow_unsafe_unwind: bool = false

If `true`, stack unwinding strategies which may cause crashes are used as a last resort. If `false`, only known-safe mechanisms will be attempted.
