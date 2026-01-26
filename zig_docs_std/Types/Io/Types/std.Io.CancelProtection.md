# std.Io.CancelProtection

In rare cases, it is desirable to completely block cancelation notification, so that a region of code can run uninterrupted before `error.Canceled` is potentially observed. Therefore, every task has a "cancel protection" state which indicates whether or not `Io` functions can introduce cancelation points.

To modify a task's cancel protection state, see `swapCancelProtection`.

For a description of cancelation and cancelation points, see `Future.cancel`.

### Fields

    unblocked

Any call to an `Io` function with `error.Canceled` in its error set is a cancelation point.

This is the default state, which all tasks are created in.

    blocked

No `Io` function introduces a cancelation point (`error.Canceled` will never be returned).
