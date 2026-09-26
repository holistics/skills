### concat

```aml
concat(value1, value2, ...)
```

```aml title="Examples"
concat('Hello', ' ', 'World') // -> Hello World
concat('Hello', ' ', 'World', '!') // -> Hello World!
```

**Description**

This function concatenates multiple strings into a single string.

**Return type**

Text

---

### find

```aml
find(text, substring)
```

**Description**

Returns the position of the first occurrence of a substring within a text string.
The returned position is a positive number starting from 1. Returns 0 if the substring is not found.

**Aliases**

`find_index`

**Return type**

Number

**Examples**

```aml title="Find the position of 'World' in 'Hello World'"
find('Hello World', 'World')  // Returns 7
```

```aml title="Find the position of 'o' in 'Hello World'"
find('Hello World', 'o')  // Returns 5
```

```aml title="Find the position of 'Universe' in 'Hello World'"
find('Hello World', 'Universe')  // Returns 0
```

---

### left

```aml
left(text, length)
```

**Description**

Returns the leftmost characters of a text string, up to the specified length.

**Return type**

Text

**Examples**

```aml title="Get the first 5 characters of 'Hello World'"
left('Hello World', 5)  // Returns 'Hello'
```

```aml title="Get the first 10 characters of 'Hello'"
left('Hello', 10)  // Returns 'Hello'
```

---

### right

```aml
right(text, length)
```

**Description**

Returns the rightmost characters of a text string, up to the specified length.

**Return type**

Text

**Examples**

```aml title="Get the last 5 characters of 'Hello World'"
right('Hello World', 5)  // Returns 'World'
```

```aml title="Get the last 10 characters of 'Hello'"
right('Hello', 10)  // Returns 'Hello'
```

---

### mid

```aml
mid(text, start, length)
```

**Description**

Extracts a substring of a specified length from a text string, starting at a given position.

* `text`: the text string
* `start`: the position where the extraction starts. It must be a positive number. The first position in the text is 1.
* `length`: the (maximum) length of the substring

**Return type**

Text

**Examples**

```aml title="Extract 'World' from 'Hello World'"
mid('Hello World', 7, 5)  // Returns 'World'
```

```aml title="Extract 'llo' from 'Hello World' starting from position 3"
mid('Hello World', 3, 3)  // Returns 'llo'
```

---

### len

```aml
len(text)
```

**Description**

Returns the length of a text string (number of characters).

**Return type**

Number

**Examples**

```aml title="Get the length of 'Hello World'"
len('Hello World')  // Returns 11
```

```aml title="Get the length of an empty string"
len('')  // Returns 0
```

---

### lpad

```aml
lpad(text, length, pad_string)
```

**Description**

Pads the left side of a text string with a specified pad string until it reaches the specified length. If the text is already longer than the length it will be truncated.

**Return type**

Text

**Examples**

```aml title="Pad 'Hello' to length 10 with ' '"
lpad('Hello', 10, ' ')  // Returns '     Hello'
```

```aml title="Pad 'Hello' to length 10 with 'abc'"
lpad('Hello', 10, 'abc')  // Returns 'abcabHello'
```

```aml title="Pad 'Hello World' to length 10 with '0'"
lpad('Hello World', 10, '0')  // Returns 'Hello Worl'
```

---

### rpad

```aml
rpad(text, length, pad_string)
```

**Description**

Pads the right side of a text string with a specified pad string until it reaches the specified length. If the text is already longer than the length it will be truncated.

**Return type**

Text

**Examples**

```aml title="Pad 'Hello' to length 10 with ' '"
rpad('Hello', 10, ' ')  // Returns 'Hello     '
```

```aml title="Pad 'Hello' to length 10 with 'abc'"
rpad('Hello', 10, 'abc')  // Returns 'Helloabcab'
```

```aml title="Pad 'Hello World' to length 10 with '0'"
rpad('Hello World', 10, '0')  // Returns 'Hello Worl'
```

---

### lower

```aml
lower(text)
```

**Description**

Converts a text string to lowercase.

**Return type**

Text

**Examples**

```aml title="Convert 'Hello World' to lowercase"
lower('Hello World')  // Returns 'hello world'
```

```aml title="Convert 'HELLO' to lowercase"
lower('HELLO')  // Returns 'hello'
```

---

### upper

```aml
upper(text)
```

**Description**

Converts a text string to uppercase.

**Return type**

Text

**Examples**

```aml title="Convert 'Hello World' to uppercase"
upper('Hello World')  // Returns 'HELLO WORLD'
```

```aml title="Convert 'hello' to uppercase"
upper('hello')  // Returns 'HELLO'
```

---

### trim

```aml
trim(text)
```

**Description**

Removes leading and trailing whitespace from a text string.

**Return type**

Text

**Examples**

```aml title="Trim whitespace from '  Hello World  '"
trim('  Hello World  ')  // Returns 'Hello World'
```

```aml title="Trim whitespace from ' Hello '"
trim(' Hello ')  // Returns 'Hello'
```

---

### ltrim

```aml
ltrim(text)
```

**Description**

Removes leading whitespace from a text string.

**Return type**

Text

**Examples**

```aml title="Trim leading whitespace from '  Hello World'"
ltrim('  Hello World')  // Returns 'Hello World'
```

```aml title="Trim leading whitespace from ' Hello '"
ltrim(' Hello ')  // Returns 'Hello '
```

---

### rtrim

```aml
rtrim(text)
```

**Description**

Removes trailing whitespace from a text string.

**Return type**

Text

**Examples**

```aml title="Trim trailing whitespace from 'Hello World  '"
rtrim('Hello World  ')  // Returns 'Hello World'
```

```aml title="Trim trailing whitespace from ' Hello '"
rtrim(' Hello ')  // Returns ' Hello'
```

---

### regexp_extract

```aml
regexp_extract(text, regex, [occurrence], [group: _group], [flags: _flags])
```

**Description**

Extracts a substring from a text string that matches a regular expression pattern.

**Return type**

Text

**Examples**

```aml title="Extract a number from a string"
regexp_extract('Product123', '[0-9]+')  // Returns '123'
```

```aml title="Extract the second word from a string"
regexp_extract('Hello World Example', '\\w+', 2) // Returns 'World'
```

```aml title="Extract text with case-insensitive match"
regexp_extract('Hello World', 'hello', flags: 'i') // Returns 'Hello'
```

```aml title="Extract a substring with a capture group"
regexp_extract('Product123.3', '(\\d+)\\.\\d+', group: 1) // Returns '123'
```

**Parameters**

- `text`: The text string to search within
- `regex`: The regular expression pattern to match (exact regex syntax depends on the database)
- `occurrence` (optional): The position of the occurrence to return. E.g. `1` means return the **first** occurrence that matches the regex.
- `group` (optional): The capture group to extract from the matched occurrence (BigQuery does not support this)
- `flags` (optional): Flags to modify the behavior of the regular expression matching (supported flags depend on the database)

**Notes**

This function is not supported in the following databases:

- SQL Server

For BigQuery, the `group` parameter is not supported. BigQuery will automatically extract the *first* capture group if one exists in the regex. BigQuery will throw an error if the regex has multiple capture groups. To use grouping without extracting a specific group, utilize [non-capture groups](https://www.regular-expressions.info/brackets.html).

---

### regexp_like

```aml
regexp_like(text, regex, [flags: _flags])
```

**Description**

Checks if a text string matches a regular expression pattern.

**Return type**

Truefalse

**Examples**

```aml title="Check if a string contains a number"
regexp_like('Product123', '[0-9]+')  // Returns true
```

```aml title="Check if a string starts with 'hello' (case insensitive)"
regexp_like('Hello World', '^hello', flags: 'i')  // Returns true
```

**Parameters**

- `text`: The text string to search within
- `regex`: The regular expression pattern to match (exact regex syntax depends on the database)
- `flags` (optional): Flags to modify the behavior of the regular expression matching (supported flags depend on the database)

**Notes**

This function is not supported in the following databases:

- SQL Server

---

### regexp_replace

```aml
regexp_replace(text, regex, substitute, [flags: _flags])
```

**Description**

Replaces substrings in a text that match a regular expression pattern with a specified replacement text.

**Return type**

Text

**Examples**

```aml title="Replace all numbers in a text with 'X'"
regexp_replace('Product123', '[0-9]+', 'X')  // Returns 'ProductX'
```

```aml title="Remove redundant whitespace from a text"
regexp_replace('Hello   World', '\\s+', ' ')  // Returns 'Hello World'
```

```aml title="Swap the first and last name"
regexp_replace('John Doe', '(\\w+) (\\w+)', '\\2, \\1')  // Returns 'Doe, John'
```

**Parameters**

- `text`: The text string to perform the replacement in
- `regex`: The regular expression pattern to match (exact regex syntax depends on the database)
- `substitute`: The replacement string. You can use backreferences like `\\1` or `$1` (depending on the specific database) to refer to captured groups in the regex
- `flags` (optional): Flags to modify the behavior of the regular expression matching (supported flags depend on the database)

**Notes**

This function is not supported in the following databases:

- SQL Server

---

### replace

```aml
replace(text, old_substring, new_substring)
```

**Description**

Replaces all occurrences of a substring within a text string with a new substring.

**Return type**

Text

**Examples**

```aml title="Replace 'World' with 'Universe' in 'Hello World'"
replace('Hello World', 'World', 'Universe')  // Returns 'Hello Universe'
```

```aml title="Replace all 'o' with '0' in 'Hello World'"
replace('Hello World', 'o', '0')  // Returns 'Hell0 W0rld'
```

---

### split_part

```aml
split_part(text, delimiter, part_number)
```

**Description**

Splits a text string into parts based on a delimiter and returns the specified part.
`part_number` is the number of the part to return, starting from 1. It must be a positive number.

**Return type**

Text

**Examples**

```aml title="Get the second part of 'apple,banana,cherry' split by ','"
split_part('apple,banana,cherry', ',', 2)  // Returns 'banana'
```

```aml title="Get the first part of 'Hello World' split by ' '"
split_part('Hello World', ' ', 1)  // Returns 'Hello'
```

**Notes**

This function is not supported in the following databases:
- Microsoft SQL Server
