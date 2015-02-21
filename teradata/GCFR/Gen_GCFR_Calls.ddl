REPLACE VIEW <GCFR_V>.Gen_GCFR_Calls AS
SELECT
    t02.stream_name
    ,t01.stream_key
    ,'CALL ${GCFR_P_PP}.'||
    (CASE
        WHEN t01.process_type = 21 THEN 'GCFR_PP_BKEY'
        WHEN t01.process_type = 22 THEN 'GCFR_PP_BMAP'
        WHEN t01.process_type = 23 THEN 'GCFR_PP_TfmFull'
        WHEN t01.process_type = 24 THEN 'GCFR_PP_TfmDelta'
        WHEN t01.process_type = 25 THEN 'GCFR_PP_BMAP'
     end)||
    '('''||
    trim(t01.process_name)||
    ''', 6, :returnCode, :returnMessage);' AS SLJM_Text
    ,'CALL DEV1_P_PP.'||
    (CASE
        WHEN t01.process_type = 21 THEN 'GCFR_PP_BKEY'
        WHEN t01.process_type = 22 THEN 'GCFR_PP_BMAP'
        WHEN t01.process_type = 23 THEN 'GCFR_PP_TfmFull'
        WHEN t01.process_type = 24 THEN 'GCFR_PP_TfmDelta'
        WHEN t01.process_type = 25 THEN 'GCFR_PP_BMAP'
     end)||
    '('''||
    trim(t01.process_name)||
    ''', 6, :returnCode, :returnMessage);' AS SQLA_Text
FROM <GCFR_V>.gcfr_process AS t01
JOIN <GCFR_V>.gcfr_stream AS t02
ON t01.stream_key = t02.stream_key
where t01.process_type IN (21, 22, 23, 24, 25)
UNION
SELECT
    t02.stream_name
    ,t01.stream_key
    ,'CALL ${GCFR_P_CP}.GCFR_CP_StreamBusDate_Start('||
    TRIM(t01.stream_key)||
    ', 6, :returnCode, :returnMessage);' AS SLJM_Text
    ,'CALL DEV1_P_CP.GCFR_CP_StreamBusDate_Start('||
    TRIM(t01.stream_key)||
    ', 6, :returnCode, :returnMessage);' AS SQLA_Text
FROM <GCFR_V>.gcfr_process AS t01
JOIN <GCFR_V>.gcfr_stream AS t02
ON t01.stream_key = t02.stream_key
where t01.process_type IN (21, 22, 23, 24, 25)
UNION
SELECT
    t02.stream_name
    ,t01.stream_key
    ,'CALL ${GCFR_P_CP}.GCFR_CP_StreamBusDate_End('||
    TRIM(t01.stream_key)||
    ', 6, :returnCode, :returnMessage);' AS SLJM_Text
    ,'CALL DEV1_P_CP.GCFR_CP_StreamBus_Date_End('||
    TRIM(t01.stream_key)||
    ', 6, :returnCode, :returnMessage);' AS SQLA_Text
FROM <GCFR_V>.gcfr_process AS t01
JOIN <GCFR_V>.gcfr_stream AS t02
ON t01.stream_key = t02.stream_key
where t01.process_type IN (21, 22, 23, 24, 25)
UNION
SELECT
    t02.stream_name
    ,t01.stream_key
    ,'CALL ${GCFR_P_CP}.GCFR_CP_Stream_Start('||
    TRIM(t01.stream_key)||
    ', null, 6, :returnCode, :returnMessage);' AS SLJM_Text
    ,'CALL DEV1_P_CP.GCFR_CP_Stream_Start('||
    TRIM(t01.stream_key)||
    ', null, 6, :returnCode, :returnMessage);' AS SQLA_Text
FROM <GCFR_V>.gcfr_process AS t01
JOIN <GCFR_V>.gcfr_stream AS t02
ON t01.stream_key = t02.stream_key
where t01.process_type IN (21, 22, 23, 24, 25)
UNION
SELECT
    t02.stream_name
    ,t01.stream_key
    ,'CALL ${GCFR_P_CP}.GCFR_CP_Stream_End('||
    TRIM(t01.stream_key)||
    ', 6, :returnCode, :returnMessage);' AS SLJM_Text
    ,'CALL DEV1_P_CP.GCFR_CP_Stream_End('||
    TRIM(t01.stream_key)||
    ', 6, :returnCode, :returnMessage);' AS SQLA_Text
FROM <GCFR_V>.gcfr_process AS t01
JOIN <GCFR_V>.gcfr_stream AS t02
ON t01.stream_key = t02.stream_key
where t01.process_type IN (21, 22, 23, 24, 25)
;

comment on view <GCFR_V>.Gen_GCFR_Calls is 'Generate list of single process execution calls. For execution via SLJM (with variable) and for SQL Assistant directly.'
;
