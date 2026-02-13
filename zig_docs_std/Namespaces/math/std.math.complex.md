# std.math.complex

## Types

- Complex

## Functions

`pub fn abs(z: anytype) @TypeOf(z.re, z.im)`
Returns the absolute value (modulus) of z.

`pub fn acos(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the arc-cosine of z.

`pub fn acosh(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the hyperbolic arc-cosine of z.

`pub fn arg(z: anytype) @TypeOf(z.re, z.im)`
Returns the angular component (in radians) of z.

`pub fn asin(z: anytype) Complex(@TypeOf(z.re, z.im))`

`pub fn asinh(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the hyperbolic arc-sine of z.

`pub fn atan(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the arc-tangent of z.

`pub fn atanh(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the hyperbolic arc-tangent of z.

`pub fn conj(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the complex conjugate of z.

`pub fn cos(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the cosine of z.

`pub fn cosh(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the hyperbolic arc-cosine of z.

`pub fn exp(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns e raised to the power of z (e^z).

`pub fn log(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the natural logarithm of z.

`pub fn pow(z: anytype, s: anytype) Complex(@TypeOf(z.re, z.im, s.re, s.im))`
Returns z raised to the complex power of c.

`pub fn proj(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the projection of z onto the riemann sphere.

`pub fn sin(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the sine of z.

`pub fn sinh(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the hyperbolic sine of z.

`pub fn sqrt(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the square root of z. The real and imaginary parts of the result have the same sign as the imaginary part of z.

`pub fn tan(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the tangent of z.

`pub fn tanh(z: anytype) Complex(@TypeOf(z.re, z.im))`
Returns the hyperbolic tangent of z.
