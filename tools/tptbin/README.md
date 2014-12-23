Here are some tools for the binary format of TPT (Teradata Parallel Transporter).

They usually operate on files, so no piping is currently supported.

Every record **must** follow the format:

1. Two byte which store the length of one logical record (this two bytes are not included in the record length)
2. (Optional) Null indicator. For every 8 columns one byte. A set bit indicates a null column. From left to right.
3. Two byte which store the length of the next column (if field is null (indicated by null indicator)), this two bytes are still required.
4. Content of the column

No CR or else is required.

# Compile

```
make clean
make all
```

# tptbin2csv

Features:

* Cut columns from file. Choose from a range (-a, -b), or explicitly select columns (-c).
* Cut rows from file. Choose from a range (-f, -t), or explicitly select rows (-r). A maximum of 10000 rows with select allowed.
* Define field delimiter (-d) (up to ten bytes)
* Define quoting sign (-q) (up to ten bytes)

If no options (-c, -a, -b) are given, all columns are printed.

If no options (-r, -f, -t) are given, all rows are printed.

Arguments are optional:
```
 -n = number of columns (tptbincut will not try to determine the number of columns)
 -a = from column number
 -b = to column number (must be greater or equal than from column number)
 -c = select explicitly columns (separate with comma, multiple nominations allowed)
 -f = from row number
 -t = to row number (must be greater or equal than from row number)
 -r = select explicitly rows (separate with comma, multiple nominations will be removed)
 -q = quote every column with that characters
 -d = delimiter between columns (if omitted, comma is used)
 -i = Include Null Indicator bytes (if omitted, no null indicator)
 -h = short help for invocation
```

# tptbincheck

Check of file consistency and some stats.

Arguments are optional:
```
 -c = number of columns (tptbincheck will not try to determine the number of columns)
 -i = Include Null Indicator bytes (if omitted, no null indicator)
 -h = short help for invocation
```

# tptbinrc

Rowcount of TPT binary files. Output is like from `wc -l`

# tptbintestfile

To create a test file in TPT binary format.

Arguments are optional:
```
 -c = number of columns (if omitted, 5 columns)
 -r = number or rows (if omitted, 1 row)
 -m = maximum number of bytes per column (if omitted, 40 bytes; maximum 62)
 -i = Include Null Indicator bytes (if omitted, no null indicator)
 -h = short help for invocation
```

Remember, number of columns times average number of bytes per column must not exceed 65535 byte
(two bytes unsigned) per line.

# tptbinview

Work in progress.

Goal is an interactive viewer for the file content, powered by ncurses!
