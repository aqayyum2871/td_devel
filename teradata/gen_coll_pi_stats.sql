-- Collect statistics on PI
-- Change Databasename

select
    (case
        when t01.columnposition = min_col_pos then 'collect statistics on '||trim(both from t01.databasename)||'.'||trim(both from t01.tablename)||' index ('
        else '  ,'
    end)||
    trim(both from t01.columnname)||
    (case
        when t01.columnposition = max_col_pos then ');'
        else ''
    end)
from  dbc.indices t01
join  (select databasename, tablename, min(columnposition) min_col_pos, max(columnposition) max_col_pos from dbc.indices where indextype = 'P' group by 1, 2) t02
on    t01.databasename = t02.databasename
and   t01.tablename = t02.tablename
where t01.databasename = <DATABASE_NAME>
and   t01.indextype = 'P'
order by t01.databasename, t01.tablename, t01.columnposition
;
