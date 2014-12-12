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

# tptbincheck

Check of file consistency and some stats.

Arguments are optional:
```
 -c = number of columns (tptbincheck will not try to determine the number of columns)
 -i = Include Null Indicator bytes (if omitted, no null indicator)
 -h = short help for invocation
```

# tptbincut

Cut columns from file. Choose from a range (-f, -t), or explicitly select columns (-s).

If no options (-s, -f, -t) are given, all columns are printed.

Can also be used to generate CSV file.

Arguments are optional:
```
 -c = number of columns (tptbincut will not try to determine the number of columns)
 -f = from column number
 -t = to column number (must be greater or equal than from column number)
 -s = select explicitly columns (separate with comma, multiple nominations allowed)
 -q = quote every column the that characters (up to 5 characters allowed)
 -d = delimiter between columns (up to 5 characters allowed, if omitted, semicolon is used)
 -i = Include Null Indicator bytes (if omitted, no null indicator)
 -h = short help for invocation
```

# tptbinrc

Rowcount of TPT binary files. Output is like from `wc -l`

# tptbinslice

Cut out certain rows of the data file.

Arguments are optional:
```
 -f = from row (if omitted, from row 1)
 -t = to row (if omitted, to row 1)
 -h = short help for invocation
```

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

# tptbinview

Work in progress.

Goal is an interactive viewer for the file content, powered by ncurses!
