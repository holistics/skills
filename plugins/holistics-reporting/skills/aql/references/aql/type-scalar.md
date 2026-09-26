<!-- Deprecated -->

<head>
   <meta name="robots" content="noindex, nofollow"/>
</head>


Scalar types are AQL’s generic equivalent of SQL predefined types (types that can be defined as the type of a column). All the currently fully supported scalar types are:


| Type | Description |
| --- | --- |
| Date | Date value like 2022-01-02 |
| Datetime | Whole datetime value like 2022-01-02 20:10:00 with built-in time zone handling |
| Number | Numeric, Float, Double, and Integer all fall under this category |
| Text | A string of characters. |
| Truefalse | A boolean value, represented as either "true" or "false". |

The following scalar types, while they exist cannot be used in any way, since we don’t support any operations on them:

| Type | Description |
| --- | --- |
| Time | A point in time, represented as a timestamp or a time string |
| Duration | A length of time, represented as a duration string |
| Composite | A combination of multiple scalar types |
| Binary | A binary data, represented as a sequence of bytes |
| Unknown | A scalar type that cannot be identified or is not yet supported |
