# std.math.FloatRepr.BiasedExponent

### Fields

    denormal = 0

    min_normal = 1

    zero = (1 << (exponent_bits - 1)) - 1

    max_normal = (1 << exponent_bits) - 2

    infinite = (1 << exponent_bits) - 1

    _

## Values

|     |     |     |
|-----|-----|-----|
| Int |     |     |

## Functions

`pub fn bias(unbiased: Exponent) BiasedExponent`

`pub fn unbias(biased: BiasedExponent) Exponent`
