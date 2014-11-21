#!/usr/bin/perl
###########################################################################
# 
# Purpose:      Teradata GCFR Stored Procdure Common Subroutines
#  
# History:
#
# Created By: Daniel O'Hara    2013-06-13
# Updated By: mf255005    2013-07-05 - Added more Command Line arguments and small changes in code
# Updated By: mf255005    2013-11-27 to 2013-12-06 
#		Description: Added new Stored procedure calls for Bulk patterns
#					Corrected the order of parameters in sub function named - GCFR_FF_RegisterFile_Initiate 
# Updated By: Imad ud din 2014-01-30 13:20 PM
#	Description: Fix for issue no. 196 - Length of oReturn_Message (output param of GCFR SPs) is not standardized 
#
# Copyright 2013 by Teradata Corp
# All Rights Reserved
# TERADATA CONFIDENTIAL INFORMATION
# FOR USE ONLY BY TERADATA ASSOCIATES AND LICENSED CUSTOMERS
#
# Version Information (Do not edit lines below)
# $Date: 2014-10-15 12:28:47 +0200 (Mi, 15 Okt 2014) $
# $Revision: 505 $
# $Author: aw230056 $
#
###########################################################################
#! /bin/perl

use strict;
#use warnings;

# Subroutine close database connection and end exit perl script.
sub CloseDBandExit($$)
{
    my $dbh = shift;
    my $gcfrProcDebugLevel = shift;
    LogMsgLevel(4,$gcfrProcDebugLevel,"Disconnecting Database...");
    $dbh->disconnect;
    LogMsgLevel(5,$gcfrProcDebugLevel,"Database disconnected!");
    ErrExit(1);
}


# Subroutine to call specified GCFR procedure with up to three input parameters that return only a return code and return message.
# This is used for:
#   GCFR_CP_StreamBusDate_Start
#   GCFR_CP_StreamBusDate_End
#   GCFR_CP_StreamSpecBD_Start 
#   GCFR_CP_Stream_Start
#   GCFR_CP_Stream_End
#   GCFR_PP_BKEY
#   GCFR_PP_BMAP
#   GCFR_PP_TfmDelta
#   GCFR_PP_TfmFull
#   GCFR_PP_TfmTxn
sub GCFR_SP
{
    my $noParam = (scalar @_ - 2)/2;
    my ($dbh, $gcfrDB, $GCFR_SP, $param1, $param1Type, $param2, $param2Type, $param3, $param3Type) = (@_);
    my ($returnCode, $returnMessage);

    my $gcfrProcDebugLevel = $param2;
    if ($noParam >= 3) {$gcfrProcDebugLevel = $param3}

    my $sql = "CALL $gcfrDB.$GCFR_SP(";
    if ($noParam >= 1) {$sql .= "?,"}
    if ($noParam >= 2) {$sql .= "?,"}
    if ($noParam >= 3) {$sql .= "?,"}
    $sql .= "?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    my $ParamNo = 0;
    if ($noParam >= 1) 
	{
		if(lc $param1Type eq "text") 
		{$sth->bind_param(++$ParamNo, "$param1")} 
		else {$sth->bind_param(++$ParamNo, $param1)}
	}
    if ($noParam >= 2) 
	{
		if (not defined ($param2))
		{
			if ($param2Type eq "text" or $param2Type eq "TimeStamp")
			{
				$param2='';
			}
			if ($param2Type eq "Numeric")
			{
				$param2=0;
			}
		}
		if(lc $param2Type eq "text") 
		{
			$sth->bind_param(++$ParamNo, "$param2")
		} 
		else 
		{
			$sth->bind_param(++$ParamNo, $param2)
		}
	}
    if ($noParam >= 3) 
	{
		if (not defined ($param3))
		{
			if ($param3Type eq "text")
			{
				$param3='';
			}
			if ($param3Type eq "Numeric")
			{
				$param3=0;
			}
		}
		if(lc $param3Type eq "text") 
		{
			$sth->bind_param(++$ParamNo, "$param3")
		}				
		else
		{
			$sth->bind_param(++$ParamNo, $param3)
		}	
	}
    $sth->bind_param_inout(++$ParamNo, \$returnCode, 6);
    $sth->bind_param_inout(++$ParamNo, \$returnMessage, 255);
    my $Message = "Executing 'CALL $gcfrDB.$GCFR_SP(";
    if ($noParam >= 1) {if(lc $param1Type eq "text") {$Message .= "'$param1',"} else {$Message .= "$param1,"}}
    if ($noParam >= 2) {if(lc $param2Type eq "text") {$Message .= "'$param2',"} else {$Message .= "$param2,"}}
    if ($noParam >= 3) {if(lc $param3Type eq "text") {$Message .= "'$param3',"} else {$Message .= "$param3,"}}

    $Message .= "returnCode,returnMessage);'...";
    LogMsgLevel(4,$gcfrProcDebugLevel,$Message);
    $sth->execute() ;

    if ($sth->err())
    {
         LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:\n" . $sth->errstr());
         ErrExit(1);
    }
    else
    {
        my @row = $sth->fetchrow_array;
		$returnCode  = $row[0];
		$returnMessage   = $row[1];
		
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"*** Error **** Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return($returnCode, $returnMessage);
}


sub GCFR_PP_Reg_DataSet_Loaded($$$$$$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrStreamKey, $gcfrBusDateCycleStartTs, $fileQualifier, $dataFileName, $ctlFileName, $countSource) = (@_);
    my ($returnCode, $returnMessage, $processState);

    my $sql = "CALL $gcfrDB.GCFR_PP_Reg_DataSet_Loaded(?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, $gcfrStreamKey);
    $sth->bind_param(4, $gcfrBusDateCycleStartTs);
    $sth->bind_param(5, $fileQualifier);
    $sth->bind_param(6, "$dataFileName");
    $sth->bind_param(7, "$ctlFileName");
    $sth->bind_param(8, $countSource);
    $sth->bind_param_inout(9, \$returnCode, 6);
    $sth->bind_param_inout(10, \$returnMessage, 255);
    $sth->bind_param_inout(11, \$processState, 6);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_PP_Reg_DataSet_Loaded('$gcfrProcessName',$gcfrProcDebugLevel,$gcfrStreamKey,$gcfrBusDateCycleStartTs,$fileQualifier,'$dataFileName','$ctlFileName',$countSource,returnMessage,processState);'...");
    $sth->execute();

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"*** Error **** Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$processState  = $row[2];
		
		$sth->finish;
        if ($returnCode == 0)
        {
            #No Error
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processState  = $processState");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processState  = $processState");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode, $returnMessage, $processState);
}



sub GCFR_PP_Reg_DataSet_Exported($$$$$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrBusDateCycleStartTs, $fileQualifier, $dataFileName, $ctlFileName, $countSource) = (@_);
    my ($returnCode, $returnMessage, $processState);

    my $sql = "CALL $gcfrDB.GCFR_PP_Reg_DataSet_Exported(?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, $gcfrBusDateCycleStartTs);
    $sth->bind_param(4, $fileQualifier);
    $sth->bind_param(5, "$dataFileName");
    $sth->bind_param(6, "$ctlFileName");
    $sth->bind_param(7, $countSource);
    $sth->bind_param_inout(8, \$returnCode, 6);
    $sth->bind_param_inout(9, \$returnMessage, 255);
    $sth->bind_param_inout(10, \$processState, 6);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_PP_Reg_DataSet_Exported('$gcfrProcessName',$gcfrProcDebugLevel,$gcfrBusDateCycleStartTs,$fileQualifier,'$dataFileName','$ctlFileName',$countSource,returnMessage,processState);'...");
    $sth->execute();

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"*** Error **** Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$processState  = $row[2];
		
		$sth->finish;
        if ($returnCode == 0)
        {
            #No Error
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processState  = $processState");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processState  = $processState");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode, $returnMessage, $processState);
}



sub GCFR_FF_RegisterFile_Initiate($$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $processType, $gcfrProcDebugLevel) = (@_);
    my ($returnCode, $returnMessage, $processState, $returnParms, $streamKey, $businessDate, $businessDateCycleNum);

    my $sql = "CALL $gcfrDB.GCFR_FF_RegisterFile_Initiate(?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, $gcfrProcessName);
    $sth->bind_param(2, $gcfrProcDebugLevel);
	$sth->bind_param(3, $processType);
    $sth->bind_param_inout(4, \$returnCode, 6);
    $sth->bind_param_inout(5, \$returnMessage, 255);
    $sth->bind_param_inout(6, \$processState, 6);
    $sth->bind_param_inout(7, \$returnParms, 4000);
    $sth->bind_param_inout(8, \$streamKey, 6);
    $sth->bind_param_inout(9, \$businessDate, 10);
    $sth->bind_param_inout(10, \$businessDateCycleNum, 11);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL gcfrDB.GCFR_FF_RegisterFile_Initiate($gcfrProcessName,$gcfrProcDebugLevel,$processType,returnCode,returnMessage,processState,returnParms,streamKey,businessDate,businessDateCycleNum );'...");
    $sth->execute() ;

    if ($sth->err())
    {
         LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
         ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$processState  = $row[2];
		$returnParms   = $row[3];
		$streamKey     = $row[4];
		$businessDate  = $row[5];
		$businessDateCycleNum = $row[6];
				
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode           = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage        = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processState         = $processState");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnParms          = $returnParms");
            LogMsgLevel(5,$gcfrProcDebugLevel,"streamKey            = $streamKey");
            LogMsgLevel(5,$gcfrProcDebugLevel,"businessDate         = $businessDate");
            LogMsgLevel(5,$gcfrProcDebugLevel,"businessDateCycleNum = $businessDateCycleNum");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode           = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage        = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processState         = $processState");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnParms          = $returnParms");
            LogMsgLevel(1,$gcfrProcDebugLevel,"streamKey            = $streamKey");
            LogMsgLevel(1,$gcfrProcDebugLevel,"businessDate         = $businessDate");
            LogMsgLevel(1,$gcfrProcDebugLevel,"businessDateCycleNum = $businessDateCycleNum");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode, $returnMessage, $processState, $returnParms, $streamKey, $businessDate, $businessDateCycleNum);
}


sub GCFR_FF_Register_Ctl_Prepare($$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $procType, $procState, $tdServer, $dbUser, $dbUserPwd, $tempDB) = (@_);
    my ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText);

    my $sql = "CALL $gcfrDB.GCFR_FF_Register_Ctl_Prepare(?,?,?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, "$procType");
    $sth->bind_param(4, "$procState");
    $sth->bind_param(5, "$tdServer");
    $sth->bind_param(6, "$dbUser");
    $sth->bind_param(7, "$dbUserPwd");
	$sth->bind_param(8, "$tempDB");
    $sth->bind_param_inout(9, \$returnCode, 6);
    $sth->bind_param_inout(10, \$returnMessage, 512);
    $sth->bind_param_inout(11, \$returnScript, 31000);
    $sth->bind_param_inout(12, \$returnParms, 300);
    $sth->bind_param_inout(13, \$returnLogonText, 1000);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_Register_Ctl_Prepare('$gcfrProcessName',$gcfrProcDebugLevel,'$procType','$procState','$tdServer','$dbUser','******','$tempDB', returnCode,returnMessage,returnScript,returnParms,returnLogonText);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$returnScript  = $row[2];
		$returnParms     = $row[3];
		$returnLogonText  = $row[4];
		
		$sth->finish;
        my $logonNoPassword = $returnLogonText;
        $logonNoPassword =~ s/UPassword *= *'[^']*'/UPassword =  '******'/;
        if ($returnCode == 0)
        {
            #No Error
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            #LogMsgLevel(6,$gcfrProcDebugLevel,"returnScript  =\n *** Start TPT Script ***\n$returnScript\n*** End of TPT Script\n");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnParms   = $returnParms");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnLogonText  = $logonNoPassword");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnScript  =\n *** Start TPT Script ***\n$returnScript\n*** End of TPT Script\n");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnParms   = $returnParms");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnLogonText  = $logonNoPassword");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText);
	
}


sub GCFR_BB_ProcessIDState_Set($$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $processIdState, $gcfrProcDebugLevel) = (@_);
    my $activityCount;

    my $sql = "CALL $gcfrDB.GCFR_BB_ProcessIDState_Set(?,$processIdState,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, $gcfrProcessName);
    $sth->bind_param_inout(2, \$activityCount, 6);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_BB_ProcessIDState_Set($gcfrProcessName,$processIdState,activityCount);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$activityCount    = $row[0];
		
		$sth->finish;

        LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
        LogMsgLevel(5,$gcfrProcDebugLevel,"activityCount = $activityCount");
    }
    return $activityCount;
}


sub GCFR_FF_TPTLoad_Initiate($$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel) = (@_);
    my ($returnCode,$returnMessage, $processState, $processType);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTLoad_Initiate(?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param_inout(3, \$returnCode, 6);
    $sth->bind_param_inout(4, \$returnMessage, 255);
    $sth->bind_param_inout(5, \$processState, 4);
    $sth->bind_param_inout(6, \$processType, 4);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTLoad_Initiate('$gcfrProcessName',$gcfrProcDebugLevel,returnCode,returnMessage,processState,processType);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$processState     = $row[2];
		$processType      = $row[3];
			
		$sth->finish;
		if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processState     = $processState");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processType      = $processType");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processState     = $processState");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processType      = $processType");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode,$returnMessage, $processState, $processType);
}


sub GCFR_FF_TPTLoad_Generate($$$$$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $procType, $procState, $tdServer, $dbUser, $dbUserPwd) = (@_);
    my ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTLoad_Generate(?,?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, "$procType");
    $sth->bind_param(4, "$procState");
    $sth->bind_param(5, "$tdServer");
    $sth->bind_param(6, "$dbUser");
    $sth->bind_param(7, "$dbUserPwd");
    $sth->bind_param_inout(8, \$returnCode, 6);
    $sth->bind_param_inout(9, \$returnMessage, 255);
    $sth->bind_param_inout(10, \$returnScript, 31000);
    $sth->bind_param_inout(11, \$returnParms, 300);
    $sth->bind_param_inout(12, \$returnLogonText, 1000);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTLoad_Generate('$gcfrProcessName',$gcfrProcDebugLevel,'$procType','$procState','$tdServer','$dbUser','******',returnCode,returnMessage,returnScript,returnParms,returnLogonText);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$returnScript  = $row[2];
		$returnParms     = $row[3];
		$returnLogonText  = $row[4];
		
		$sth->finish;
        my $logonNoPassword = $returnLogonText;
        $logonNoPassword =~ s/UPassword *= *'[^']*'/UPassword =  '******'/;
        if ($returnCode == 0)
        {
            #No Error
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            #LogMsgLevel(6,$gcfrProcDebugLevel,"returnScript  =\n *** Start TPT Script ***\n$returnScript\n*** End of TPT Script\n");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnParms   = $returnParms");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnLogonText  = $logonNoPassword");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnScript  =\n *** Start TPT Script ***\n$returnScript\n*** End of TPT Script\n");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnParms   = $returnParms");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnLogonText  = $logonNoPassword");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText);
}


sub GCFR_FF_File_Register($$$$$$$$$$$$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrStreamKey, $businessDate, $businessDateCycleNum, $busDtCycleStTs,
        $fileQualifier, $dataFileName, $ctlFileName, $extractionDate, $extStartTs, $extEndTs, $toolSessionId, $countSource) = (@_);
    my ($returnCode, $returnMessage, $rowCount, $loadingDirectory);
	
	if (not defined($toolSessionId) )
	{
		$toolSessionId=0;
	}
    my $sql = "CALL $gcfrDB.GCFR_FF_File_Register(?,?,11,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, $gcfrStreamKey);
    $sth->bind_param(4, "$businessDate");
    $sth->bind_param(5, $businessDateCycleNum);
    $sth->bind_param(6, "$busDtCycleStTs");
    $sth->bind_param(7, $fileQualifier);
    $sth->bind_param(8, "$dataFileName");
    $sth->bind_param(9, "$ctlFileName");
    $sth->bind_param(10, $extractionDate);
    $sth->bind_param(11, $extStartTs);
    $sth->bind_param(12, $extEndTs);
    $sth->bind_param(13, $toolSessionId);
    $sth->bind_param(14, $countSource, DBI::SQL_INTEGER);
    $sth->bind_param_inout(15, \$returnCode, 6);
    $sth->bind_param_inout(16, \$returnMessage, 255);
    $sth->bind_param_inout(17, \$rowCount, 6);
    $sth->bind_param_inout(18, \$loadingDirectory, 240);

    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_File_Register($gcfrProcessName,$gcfrProcDebugLevel,11,$gcfrStreamKey,'$businessDate',$businessDateCycleNum,$busDtCycleStTs,$fileQualifier,'$dataFileName','$ctlFileName',NULL, NULL, NULL, NULL,$toolSessionId,returnCode, returnMessage, rowCount, loadingDirectory);'...");
    $sth->execute();

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$rowCount		 = $row[2];
		$loadingDirectory     = $row[3];

		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode       = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage    = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"rowCount         = $rowCount");
            LogMsgLevel(5,$gcfrProcDebugLevel,"loadingDirectory = $loadingDirectory");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode       = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage    = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"rowCount         = $rowCount");
            LogMsgLevel(1,$gcfrProcDebugLevel,"loadingDirectory = $loadingDirectory");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);            }
    }
    return ($returnCode, $returnMessage, $rowCount, $loadingDirectory);
}


sub GCFR_FF_TPTStats_SetValidate
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $rowsInput, $rowsConsidered, $rowsNotConsidered,
        $rowsRejected, $rowsInserted ,$rowsUpdated, $rowsDeleted, $rowsET, $rowsUV, $badRows, $toolSessionId) = (@_);

    my ($returnCode, $returnMessage);
	
	if (not defined($toolSessionId) )
	{
		$toolSessionId=0;
	}
	
    my $sql = "CALL $gcfrDB.GCFR_FF_TPTStats_SetValidate(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, $rowsInput);
    $sth->bind_param(4, $rowsConsidered);
    $sth->bind_param(5, $rowsNotConsidered);
    $sth->bind_param(6, $rowsRejected);
    $sth->bind_param(7, $rowsInserted);
    $sth->bind_param(8, $rowsUpdated);
    $sth->bind_param(9, $rowsDeleted);
    $sth->bind_param(10, $rowsET);
    $sth->bind_param(11, $rowsUV);
    $sth->bind_param(12, $badRows);
    $sth->bind_param(13, $toolSessionId);
    $sth->bind_param_inout(14, \$returnCode, 6);
    $sth->bind_param_inout(15, \$returnMessage, 255);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTStats_SetValidate('$gcfrProcessName',$gcfrProcDebugLevel,$rowsInput,$rowsConsidered,$rowsNotConsidered,$rowsRejected,$rowsInserted ,$rowsUpdated,$rowsDeleted,$rowsET,$rowsUV,$badRows,$toolSessionId,returnCode,returnMessage);'...");
    $sth->execute();

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
        my @row = $sth->fetchrow_array;
        $returnCode  = $row[0];
		$returnMessage   = $row[1];
			
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
}


sub GCFR_BB_ProcessId_Get($$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, , $gcfrProcDebugLevel) =(@_);
    my ($pidProcessId, $pidProcessState, $pidStreamKey,$pidStreamId, $pidBusinessDate, $pidBusinessDateCycleNum, $pidBusDateCycleStartTs, $pidUpdateDate, $pidUpdateUser, $pidUpdateTs);

    my $sql = "CALL $gcfrDB.GCFR_BB_ProcessId_Get(?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param_inout(2, \$pidProcessId, 11);
    $sth->bind_param_inout(3, \$pidProcessState, 4);
    $sth->bind_param_inout(4, \$pidStreamKey, 6);
    $sth->bind_param_inout(5, \$pidStreamId, 11);
    $sth->bind_param_inout(6, \$pidBusinessDate ,10);
    $sth->bind_param_inout(7, \$pidBusinessDateCycleNum, 11);
    $sth->bind_param_inout(8, \$pidBusDateCycleStartTs, 26);
    $sth->bind_param_inout(9, \$pidUpdateDate, 10);
    $sth->bind_param_inout(10, \$pidUpdateUser, 30);
    $sth->bind_param_inout(11, \$pidUpdateTs, 26);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing CALL $gcfrDB.GCFR_BB_ProcessId_Get('$gcfrProcessName',pidProcessId,pidProcessState,pidStreamKey,pidStreamId,pidBusinessDate,pidBusinessDateCycleNum,pidBusDateCycleStartTs,pidUpdateDate,pidUpdateUser,pidUpdateTs)");
    $sth->execute();

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
        my @row = $sth->fetchrow_array;
		$pidProcessState = $row[1];
		
		$sth->finish;
        LogMsgLevel(5,$gcfrProcDebugLevel,"Complete ...state $pidProcessState");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidProcessId            = $pidProcessId");
        LogMsgLevel(5,$gcfrProcDebugLevel,"pidProcessState         = $pidProcessState");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidStreamKey            = $pidStreamKey");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidStreamId             = $pidStreamId");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidBusinessDate         = $pidBusinessDate");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidBusinessDateCycleNum = $pidBusinessDateCycleNum");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidBusDateCycleStartTs  = $pidBusDateCycleStartTs");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidUpdateDate           = $pidUpdateDate");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidUpdateUser           = $pidUpdateUser");
        #LogMsgLevel(5,$gcfrProcDebugLevel,"pidUpdateTs             = $pidUpdateTs");
    }
    return ($pidProcessId, $pidProcessState, $pidStreamKey,$pidStreamId, $pidBusinessDate, $pidBusinessDateCycleNum, $pidBusDateCycleStartTs, $pidUpdateDate, $pidUpdateUser, $pidUpdateTs)
}


sub GCFR_FF_TPTLoad_Complete($$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel) = (@_);
    my ($returnCode, $returnMessage, $activityCount);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTLoad_Complete(?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param_inout(3, \$returnCode, 6);
    $sth->bind_param_inout(4, \$returnMessage, 255);
    $sth->bind_param_inout(5, \$activityCount, 11);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTLoad_Complete('$gcfrProcessName',$gcfrProcDebugLevel,returnCode,returnMessage,activityCount);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode  = $row[0];
		$returnMessage   = $row[1];
		$activityCount = $row[2];
		
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"activityCount = $activityCount");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"activityCount = $activityCount");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
}


sub GCFR_FF_TPTExport_Initiate($$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel) = (@_);
    my ($returnCode, $returnMessage, $processState, $processType);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTExport_Initiate(?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param_inout(3, \$returnCode, 11);
    $sth->bind_param_inout(4, \$returnMessage, 255);
    $sth->bind_param_inout(5, \$processState, 4);
    $sth->bind_param_inout(6, \$processType, 4);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTExport_Initiate('$gcfrProcessName',$gcfrProcDebugLevel,returnCode,returnMessage,processState,processType);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
        my @row = $sth->fetchrow_array;
		$returnCode     = $row[0];
		$returnMessage  = $row[1];
		$processState 	  = $row[2];
		$processType 	  = $row[3];
		
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processState  = $processState");
            LogMsgLevel(5,$gcfrProcDebugLevel,"processType   = $processType");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processState  = $processState");
            LogMsgLevel(1,$gcfrProcDebugLevel,"processType   = $processType");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode, $returnMessage, $processState, $processType);
}


sub GCFR_FF_TPTExport_Prepare($$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $procType) = (@_);
    my ($returnCode, $returnMessage);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTExport_Prepare(?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, "$procType");
    $sth->bind_param_inout(4, \$returnCode, 6);
    $sth->bind_param_inout(5, \$returnMessage, 255);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTExport_Prepare('$gcfrProcessName',$gcfrProcDebugLevel,'$procType',returnCode,returnMessage);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode, $returnMessage);
}


sub GCFR_FF_TPTExport_Generate($$$$$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $procType, $procState, $tdServer, $dbUser, $dbUserPwd) = (@_);
    my ($returnCode, $returnMessage, $returnParms, $returnScript, $returnLogonText);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTExport_Generate(?,?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, "$procType");
    $sth->bind_param(4, "$procState");
    $sth->bind_param(5, "$tdServer");
    $sth->bind_param(6, "$dbUser");
    $sth->bind_param(7, "$dbUserPwd");
    $sth->bind_param_inout(8, \$returnCode, 6);
    $sth->bind_param_inout(9, \$returnMessage, 255);
    $sth->bind_param_inout(10, \$returnParms, 100);
    $sth->bind_param_inout(11, \$returnScript, 255);
    $sth->bind_param_inout(12, \$returnLogonText, 32000);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTExport_Generate('$gcfrProcessName',$gcfrProcDebugLevel,$procType,$procState,$tdServer,$dbUser,******,returnCode,returnMessage,returnParms,returnScript,returnLogonText);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$returnParms	 = $row[2];
		$returnScript            = $row[3];
		$returnLogonText  = $row[4];
		
		$sth->finish;
        my $logonNoPassword = $returnLogonText;
        $logonNoPassword =~ s/UPassword *= *'[^']*'/UPassword =  '******'/;
        if ($returnCode == 0)
        {
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode      = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage   = $returnMessage");
            #LogMsgLevel(6,$gcfrProcDebugLevel,"returnScript    = \n *** Start TPT Script ***\n$returnScript\n*** End of TPT Script\n");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnParms     = $returnParms");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnLogonText = $logonNoPassword");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode      = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage   = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnScript    = \n *** Start TPT Script ***\n$returnScript\n*** End of TPT Script\n");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnParms     = $returnParms");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnLogonText = $logonNoPassword");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode, $returnMessage, $returnParms, $returnScript, $returnLogonText);
}


sub GCFR_FF_TPTExport_Complete($$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $rowsExported, $toolSessionId) = (@_);
    my ($returnCode, $returnMessage, $activityCount);
	
	if (not defined($toolSessionId) )
	{
		$toolSessionId=0;
	}

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTExport_Complete(?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, $rowsExported);
    $sth->bind_param(4, $toolSessionId);
    $sth->bind_param_inout(5, \$returnCode, 11);
    $sth->bind_param_inout(6, \$returnMessage, 255);
    $sth->bind_param_inout(7, \$activityCount, 11);
    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTExport_Complete('$gcfrProcessName',$gcfrProcDebugLevel,$rowsExported,$toolSessionId,returnCode,returnMessage,activityCount);'...");
    $sth->execute()    ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		$activityCount = $row[2];
		
		$sth->finish;
        if ($returnCode == 0)
        {
            LogMsgLevel(6,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(6,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(6,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(6,$gcfrProcDebugLevel,"activityCount = $activityCount");
        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");
            LogMsgLevel(1,$gcfrProcDebugLevel,"activityCount = $activityCount");
            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
}

sub GCFR_FF_TPTBulkLoad_CapValid($$$$$$$$$$$$$$)
{
    my ($dbh, $gcfrDB, $gcfrProcessName, $gcfrProcDebugLevel, $Ctl_Id, $File_Id, $BusDate, 
	$tempDB, $targetTable, $targetDB, $toolSessionID, $busDtCN, $busDtTS, $processId ) = (@_);
    my ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText);

    my $sql = "CALL $gcfrDB.GCFR_FF_TPTBulkLoad_CapValid(?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    my $sth = $dbh->prepare($sql) || die LogMsg("Can't prepare SQL:$DBI::errstr");
    $sth->bind_param(1, "$gcfrProcessName");
    $sth->bind_param(2, $gcfrProcDebugLevel);
    $sth->bind_param(3, $Ctl_Id);
	$sth->bind_param(4, $File_Id);
	$sth->bind_param(5, "$BusDate");
	$sth->bind_param(6, "$tempDB");
	$sth->bind_param(7, "$targetTable");
	$sth->bind_param(8, "$targetDB");
	$sth->bind_param(9, $toolSessionID);
	$sth->bind_param(10, $busDtCN);
	$sth->bind_param(11, "$busDtTS");
	$sth->bind_param(12, $processId);
    $sth->bind_param_inout(13, \$returnCode, 6);
    $sth->bind_param_inout(14, \$returnMessage, 255);

    LogMsgLevel(4,$gcfrProcDebugLevel,"Executing 'CALL $gcfrDB.GCFR_FF_TPTBulkLoad_CapValid('$gcfrProcessName',$gcfrProcDebugLevel,$Ctl_Id,$File_Id, '$BusDate', 
	'$tempDB', '$targetTable', '$targetDB', NULL, $busDtCN, '$busDtTS', $processId, returnCode, returnMessage);'...");
    $sth->execute() ;

    if ($sth->err())
    {
        LogMsgLevel(1,$gcfrProcDebugLevel,"Could not execute the SP! It has reported:" . $sth->errstr());
        ErrExit(1);
    }
    else
    {
		my @row = $sth->fetchrow_array;
		$returnCode    = $row[0];
		$returnMessage = $row[1];
		
		$sth->finish;

        if ($returnCode == 0)
        {
            #No Error
            LogMsgLevel(5,$gcfrProcDebugLevel,"Call SP Completed Without Error.");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(5,$gcfrProcDebugLevel,"returnMessage = $returnMessage");

        }
        else
        {
            LogMsgLevel(1,$gcfrProcDebugLevel,"Call SP Completed With Error!");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnCode    = $returnCode");
            LogMsgLevel(1,$gcfrProcDebugLevel,"returnMessage = $returnMessage");

            CloseDBandExit($dbh,$gcfrProcDebugLevel);
        }
    }
    return ($returnCode,$returnMessage);
}


1;
