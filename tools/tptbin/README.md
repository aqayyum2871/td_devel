Here are some tools for the binary format of TPT (Teradata Parallel Transporter).

The format is defined as:
 #. Two byte which store the length of one logical record (this two bytes are not included in the record length)
 #. (Optional) Null indicator. For every 8 columns one byte. A set bit indicates a null column. From left to right.
 #. Two byte which store the length of the next column (if field is null (indicated by null indicator)), this two bytes are still required.
 #. Content of the column

Compile
=======
make clean
make all
