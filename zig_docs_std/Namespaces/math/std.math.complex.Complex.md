# std.math.complex.Complex

A complex number consisting of a real an imaginary part. T must be a floating-point value.

## Parameters

    T: type

### Fields

    re: T

Real part.

    im: T

Imaginary part.

## Functions

`pub fn add(self: Self, other: Self) Self`
Returns the sum of two complex numbers.

`pub fn conjugate(self: Self) Self`
Returns the complex conjugate of a number.

`pub fn div(self: Self, other: Self) Self`
Returns the quotient of two complex numbers.

`pub fn init(re: T, im: T) Self`
Create a new Complex number from the given real and imaginary parts.

`pub fn magnitude(self: Self) T`
Returns the magnitude of a complex number.

`pub fn mul(self: Self, other: Self) Self`
Returns the product of two complex numbers.

`pub fn mulbyi(self: Self) Self`
Returns the product of complex number and i=sqrt(-1)

`pub fn neg(self: Self) Self`
Returns the negation of a complex number.

`pub fn reciprocal(self: Self) Self`
Returns the reciprocal of a complex number.

`pub fn squaredMagnitude(self: Self) T`

`pub fn sub(self: Self, other: Self) Self`
Returns the subtraction of two complex numbers.
