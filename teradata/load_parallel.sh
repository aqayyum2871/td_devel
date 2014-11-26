#!/bin/bash

#trap "echo RAUS" EXI

touch tmp/RUNNING.${TRG}

ts=$(date +"%Y-%m-%d %H:%M:%S")
printf "[%s][%-6s][%10s][%-61s]\n" "${ts}" "Start" "" "${TRG}"

./load.sh "${SRC}" "${TRG}"

if [ -f log/${TRG%.*}/tpt.${TRG}.log ]
then
	if [ $(grep -c "Job .* completed successfully" log/${TRG%.*}/tpt.${TRG}.log) -eq 0 ]
	then
		ts=$(date +"%Y-%m-%d %H:%M:%S")
		printf "[%s][%-6s][%10s][%-61s]\n" "${ts}" "Done" "" "${TRG}"
	else
		rowcnt=$(awk '/Total Rows Applied/ {print $5}' log/${TRG%.*}/tpt.${TRG}.log)
		ts=$(date +"%Y-%m-%d %H:%M:%S")
		printf "[%s][%-6s][%10d][%-61s]\n" "${ts}" "Done" $rowcnt "${TRG}"
		echo $rowcnt >done/${TRG%.*}/"${TRG}"
	fi
else
	ts=$(date +"%Y-%m-%d %H:%M:%S")
	printf "[%s][%-6s][%10s][%-61s] %s\n" "${ts}" "WARN" "" "${TRG}" "No Logfile found"
fi

rm tmp/RUNNING.${TRG}

exit
