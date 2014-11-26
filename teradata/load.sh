#!/bin/bash

if [ "$1" = "" ]
then
	echo "error: source table missing!"
	exit 1
else
	SRC_TAB=$1
fi

if [ "$2" = "" ]
then
	echo "error: target table missing!"
	exit 2
else
	TRG_TAB=$2
fi

if [[ -f "${TRG_TAB}.dat" || -p "${TRG_TAB}.dat" ]]
then
	rm "${TRG_TAB}.dat"
else
	mkfifo "${TRG_TAB}.dat"
fi

TRG_DB=${TRG_TAB%.*}

rm -f log/${TRG_DB}/tpt.${TRG_TAB}.log
rm -f log/${TRG_DB}/delete.${TRG_TAB}.log
rm -f log/${TRG_DB}/unload.${TRG_TAB}.log

{
	echo ".logon ${TDPID}/${TD_USERNAME},${TD_PASSWORD}"
	echo "delete from ${TRG_TAB};"
	echo ".if errorcode <> 0 then .quit errorcode"
	echo ".quit 0"
} | bteq >log/${TRG_DB}/delete.${TRG_TAB}.log 2>&1

if [ $? -ne 0 ]
then
	ts=$(date +"%Y-%m-%d %H:%M:%S")
	printf "[%s][%-6s][%10s][%-61s] %s\n" "${ts}" "Failed" "" "${TRG_TAB}" "Error while delete"
	exit 3
fi

if [ -f "tpt/${TRG_DB}/${TRG_TAB}.tpt" ]
then
	<Unload tool here> >>"${TRG_TAB}.dat" 2>log/${TRG_DB}/unload.${SRC_TAB}.log &

	tbuild -f "tpt/${TRG_DB}/${TRG_TAB}.tpt" -v target_connect.tptvar "${TRG_TAB}" >log/${TRG_DB}/tpt.${TRG_TAB}.log 2>&1
fi

rm "${TRG_TAB}.dat"

exit
