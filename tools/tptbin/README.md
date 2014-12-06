Here are some tools for the binary format of TPT (Teradata Parallel Transporter).

The format is defined as:

1. Two byte which store the length of one logical record (this two bytes are not included in the record length)
2. (Optional) Null indicator. For every 8 columns one byte. A set bit indicates a null column. From left to right.
3. Two byte which store the length of the next column (if field is null (indicated by null indicator)), this two bytes are still required.
4. Content of the column

No CR or else is required.

Compile
=======
```
make clean
make all
```
