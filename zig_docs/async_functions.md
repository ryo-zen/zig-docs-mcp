# Async Functions §

Async functions regressed with the release of 0.11.0. Their future in the Zig language is unclear due to multiple unsolved problems:

  * LLVM's lack of ability to optimize them.
  * Third-party debuggers' lack of ability to debug them.
  * [The cancellation problem](https://github.com/ziglang/zig/issues/5913).
  * Async function pointers preventing the stack size from being known.

These problems are surmountable, but it will take time. The Zig team is currently focused on other priorities.