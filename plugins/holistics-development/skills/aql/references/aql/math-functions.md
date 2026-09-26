### abs
```aml
abs(number)
```

```aml title="Examples"
abs(-1) // => 1
```

**Description**

Returns the absolute value of a number.

**Return type**

Number

---

### sqrt
```aml
sqrt(number)
```

```aml title="Examples"
sqrt(9) // => 3
sqrt(10) // => 3.1622776601683795
```


**Description**

Returns the square root of a number.

**Return type**

Number

---

### ceil

```aml
ceil(number)
```

```aml title="Examples"
ceil(1.1) // => 2
ceil(1.9) // => 2
```

**Description**

Returns the smallest integer greater than or equal to a number.

**Return type**

Number

### floor

```aml
floor(number)
```

```aml title="Examples"
floor(1.1) // => 1
floor(1.9) // => 1
```

**Description**

Returns the largest integer less than or equal to a number.

**Return type**

Number

### round

```aml
round(number)
round(number, scale)
```

```aml title="Examples"
round(1.1) // => 1
round(1.1, 0) // => 1
round(1.9, 0) // => 2
round(1.12345, 2) // => 1.12
round(-1.5) // => -2
```

**Description**

Returns the rounded value of a number to a specified number of decimal places (scale). Round away from zero if the fractional part of the number is greater than 0.5; otherwise, round towards zero.

**Return type**

Number

### trunc

```aml
trunc(number)
trunc(number, scale)
```

```aml title="Examples"
trunc(1.1) // => 1
trunc(1.1, 0) // => 1
trunc(1.9, 0) // => 1
trunc(1.12345, 2) // => 1.12
```

**Description**

Returns the truncated value of a number to a specified number of decimal places (scale).

**Return type**

Number

### exp

```aml
exp(number)
```

```aml title="Examples"
exp(1) // => 2.718281828459045
```

**Description**

Returns the value of the constant $e$ raised to the power of a number.

**Return type**

Number

### ln

```aml
ln(number)
```

```aml title="Examples"
ln(1) // => 0
```

**Description**

Returns the natural logarithm ($\log_{e}$) of a number.

**Return type**

Number

### log10

```aml
log10(number)
```

```aml title="Examples"
log10(100) // => 2
```

**Description**

Returns the base 10 logarithm ($\log_{10}$) of a number.

**Return type**

Number

### log2

```aml
log2(number)
```

```aml title="Examples"
log2(8) // => 3
```

**Description**

Returns the base 2 logarithm ($\log_{2}$) of a number.

**Return type**

Number

### pow

```aml
pow(base, exponent)
```

```aml title="Examples"
pow(2, 3) // => 8
```

**Description**

Returns the value of a base raised to the power of an exponent.

**Return type**

Number

### mod

```aml
mod(dividend, divisor)
```

```aml title="Examples"
mod(5, 2) // => 1
```

**Description**

Returns the remainder of a division operation.

**Return type**

Number

### div

```aml
div(dividend, divisor)
```

```aml title="Examples"
div(5, 2) // => 2
```

**Description**

Returns the integer quotient of a division operation.

**Return type**

Number

### sign

```aml
sign(number)
```

```aml title="Examples"
sign(5) // => 1
sign(-5) // => -1
sign(0) // => 0
```

**Description**

Returns the sign of a number: 1 if the number is positive, -1 if the number is negative, and 0 if the number is zero.

**Return type**

Number

### radians

```aml
radians(degrees)
```

```aml title="Examples"
radians(180) // => 3.141592653589793
```

**Description**

Converts degrees to radians.

**Return type**

Number

### degrees

```aml
degrees(radians)
```

```aml title="Examples"
degrees(pi()) // => 180
```

**Description**

Converts radians to degrees.

**Return type**

Number

### pi

```aml
pi()
```

```aml title="Examples"
pi() // => 3.141592653589793
```

**Description**

Returns the value of the constant π.

**Return type**

Number

### acos

```aml
acos(number)
```

```aml title="Examples"
acos(cos(pi())) // => 3.141592653589793
```

**Description**

Returns the arccosine of a number.

**Return type**

Number

### asin

```aml
asin(number)
```

```aml title="Examples"
asin(sin(pi() / 2)) // => 1.5707963267948966
```

**Description**

Returns the arcsine of a number.

**Return type**

Number

### atan

```aml
atan(number)
```

```aml title="Examples"
atan(tan(pi() / 4)) // => 0.7853981633974483
```

**Description**

Returns the arctangent of a number.

**Return type**

Number

### atan2

```aml
atan2(y, x)
```

```aml title="Examples"
atan2(2, pi()) // => 0.6366197723675814
```

**Description**

Returns the 2-argument arctangent.

**Return type**

Number

### cos

```aml
cos(number)
```

```aml title="Examples"
cos(pi()) // => -1
```

**Description**

Returns the cosine of a number.

**Return type**

Number

### sin

```aml
sin(number)
```

```aml title="Examples"
sin(pi() / 2) // => 1
```

**Description**

Returns the sine of a number.

**Return type**

Number

### tan

```aml
tan(number)
```

```aml title="Examples"
tan(pi() / 4) // => 1
```

**Description**

Returns the tangent of a number.

**Return type**

Number

### cot

```aml
cot(number)
```

```aml title="Examples"
cot(pi() / 4) // => 1
```

**Description**

Returns the cotangent of a number.

**Return type**

Number
