#!/usr/bin/perl
###########################################################################
# 
# Purpose:      Teradata GCFR Perl API Common Subroutines
#  
# History:
#
# Created By: Rajesh Singh      2012-12-03
# Modified By: Daniel O'Hara    2013-06-13
#   VersionInfo and Usage updated.
#   ShowLoadingLogFile changed to read a line at a time rather than load file to array.
#   New subroutine LogMsgLevel added with debug level for messages.
#   Added Debuglevel to RunCmd.
#   **** replaced with --- in information messages and *** used for fatal error.
#   Formating generally tidied indentation and using shift.
# Modified By: Daniel O'Hara    2013-06-13
#   Added BTEQ_Script to Usage
#
# Updated By: mf255005    2013-07-05 - Added more Command Line arguments and small changes in code
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
#
###########################################################################
#! /bin/perl

use strict;
#use warnings;
use IPC::Open3;

sub VersionInfo ()
{
###########################################################################
# 
# Purpose:      Print Version Information
#
###########################################################################
    LogMsg ( "##############################################################");
    LogMsg ( "# Teradata GCFR Standard Interface For Perl Script           #");
    LogMsg ( "# Copyright 2013 by Teradata Corp                            #");
    LogMsg ( "# All Rights Reserved                                        #");
    LogMsg ( "# TERADATA CONFIDENTIAL INFORMATION                          #");
    LogMsg ( "# FOR USE ONLY BY TERADATA ASSOCIATES AND LICENSED CUSTOMERS #");
    LogMsg ( "##############################################################");
}


sub ShowLoadingLogFile($)
{
###########################################################################
# Purpose:      Output log file as message 
# Params:       fileName    : Log File Name
###########################################################################
    my $logFileName = shift;
    LogMsg("--- Log File: $logFileName ---" );

    open(LogFile,"<$logFileName") or die "$!";
    while (my $line = <LogFile>)
    {
        LogMsg_sh($line)
    }
    close(LogFile);
    LogMsg("--- End of Log File ---" );
}

sub RunCmd($$)
{
###########################################################################
# Purpose:      Run Command From Script
###########################################################################
    my $cmdLine = shift;
    my $debugLevel = shift;
    
    if (not defined $debugLevel) {$debugLevel = 6}

    LogMsgLevel(1,$debugLevel,"Try to Run Command: $cmdLine");  
 
    my $pid = open3(\*WRITER, \*READER, \*ERROR, $cmdLine);
    # if \*ERROR is 0, stderr goes to stdout

	LogMsg("  --- Command Std Output ---");
    while (my $output = <READER>) 
	{
		if (4 <= $debugLevel )
		{
			LogMsg_sh("$output")
		}	
	}
    LogMsg("  --- End of Std Command Output ---");
    
	
    LogMsg ("  --- Command Err Output ---");
	while(my $errOut = <ERROR>) 
	{
		if (1 <= $debugLevel )
		{	
			LogMsg_sh("$errOut")
		}	
	}
	LogMsg("  --- End of Err Command Output ---");
    
	
    waitpid ($pid, 0) or die "$!\n";

    if ( $? != 0 )
    {
        LogMsg("Run Command Failed!");
        ErrExit(1);
    }
    else
    {
        LogMsg("Run Command Completed Successfully!");
    }
}
 
sub WriteFile($$)
{
###########################################################################
# Purpose:      Write into file
# Params:       paramFileName  : File Name
#               parameterString         : File Content
#
###########################################################################
    my $paramFileName = shift;
    my $parameterString = shift;
    open(FH,">$paramFileName") or die LogMsg("Can't write this file $paramFileName,$!");
    printf FH "$parameterString\n";
    close(FH); 
    return 0;
}  

sub ReadParamFile($)
{
###########################################################################
# Purpose:      Read Param File
# Params:       fileName    : File Name
# Return:       Parameter Value Array
###########################################################################
 my $fileName = shift;
   open(DsFile,"<$fileName") or die LogMsg("Can't read this file $fileName,$!");
   my(@lines) = <DsFile>;
   close(DsFile);
   return "@lines";
}
 
sub Usage()
{
###########################################################################
# Purpose:      Print Usage message
###########################################################################
    print "Usage 1: perl GCFR_Standard_Processes.pl JobId xmlParameterFileName\n";
    print "   Sample:\n";
    print "     perl GCFR_Standard_Processes.pl GCFR_Stream_BusDate_Start p_GCFR_Stream_BusDate_Start.xml\n";
    print "\n";
    print "Parameters from the supplied xml file p_GCFR_Stream_BusDate_Start.xml override those\n";
    print "in  the common xml file GCFR_common_params.xml\n";
    print "\n";
    print "Usage 2: perl GCFR_Standard_Processes.pl -job JobId [optional parameters]\n";
    print "   Samples:\n";
    print "     perl GCFR_Standard_Processes.pl -job GCFR_Stream_BusDate_Start -xml p_GCFR_Stream_BusDate_Start.xml\n";
	print "     perl GCFR_Standard_Processes.pl -job GCFR_Register_Data_Set_Availability -server tdemo -user dbc -pwd dbc -process EX_786_22_Acct\n";
    print "\n";
    print "Command line parameters will override those present in the xml files.\n";
    print "The other optional parameters are:\n";
    print "  -server tdServer\n";
    print "  -user dbUser\n";
    print "  -pwd dbUserPwd\n";
	
	
	print "  -gcfrdbview gcfrDbView\n";
	print "  -gcfrdbproc gcfrDbProc\n";
	print "  -gcfrdbcp gcfrDbProcCP\n";
	print "  -gcfrdbpp gcfrDbProcPP\n";
	print "  -gcfrdbff gcfrDbProcFF\n";
	print "  -gcfrdbbb gcfrDbProcBB\n";
	print "  -gcfrdbut gcfrDbProcUT\n";
	
    print "  -process gcfrProcessName\n";
    print "  -stream gcfrStreamKey\n";
    
	print "  -busdate gcfrBusDT\n";
	
	print "  -timestamp gcfrBusDateCycleStartTs\n";
	print "  -debuglevel gcfrProcDebugLevel\n";
    
	print "  -scriptspath gcfrScriptsPath\n";
	print "  -logspath gcfrLogsPath\n";
	print "  -paramspath gcfrParamsPath\n";
	print "  -libspath gcfrLibsPath\n";
	print "  -tptlogpath tptLogPath\n";
	
	print "  -countsource countSource\n";
    print "  -help|?\n";
    print "\n";
	
    print "Valid JobId List:\n";
    print "  GCFR_Stream_BusDate_Start\n";
    print "  GCFR_Stream_Start\n";
    print "  GCFR_Stream_End\n";
    print "  GCFR_Stream_BusDate_End\n";
	print "  GCFR_StreamSpecBD_Start\n";
    print "  GCFR_Register_Data_Set_Availability\n";
    print "  GCFR_Register_Data_Set_Loaded\n";
    print "  GCFR_TPT_Load\n";
    print "  GCFR_TPT_Load_CLOB\n";
    print "  GCFR_Bkey_PP\n";
    print "  GCFR_Bmap_PP\n";
    print "  GCFR_Tfm_Full_Apply\n";
    print "  GCFR_Tfm_Delta_Apply\n";
    print "  GCFR_Tfm_Insert_Append\n";
    print "  GCFR_TPT_Export\n";
    print "  GCFR_TPT_Export_CLOB\n";
    #print "  BTEQ_Script\n"; -- just commented out until not being used in GCFR official releases
    print "\n";
    print "Sample xml parameter file:\n";
    print "<?xml version=\"1.0\"?>";    print "<!-- Common Parameter File Template \"GCFR_common_params.xml\" -->\n";    print "<GCFR_COMMON_PARAMS>\n";    print "  <TDBSERVER>TDVM</TDBSERVER>\n";    print "  <TDBUSER>GDEV1_ETL_USR</TDBUSER>\n";    print "  <TDBPWD>GDEV1_ETL_USR</TDBPWD>\n";    print "  <GCFRDBV>GDEV1V_GCFR</GCFRDBV>\n";    print "  <GCFRDBP>GDEV1P_GCFR</GCFRDBP>\n";    print "  <GCFRDBPROC_PP>GDEV1P_PP</GCFRDBPROC_PP>\n";    print "  <GCFRDBPROC_CP>GDEV1P_CP</GCFRDBPROC_CP>\n";    print "  <GCFRDBPROC_FF>GDEV1P_FF</GCFRDBPROC_FF>\n";    print "  <GCFRDBPROC_BB>GDEV1P_BB</GCFRDBPROC_BB>\n";    print "  <GCFRDBPROC_UT>GDEV1P_UT</GCFRDBPROC_UT>\n";    print "  <PROCESS_NAME></PROCESS_NAME>\n";    print "  <SP_DEBUG_LEVEL>6</SP_DEBUG_LEVEL>\n";    print "  <STREAM_KEY></STREAM_KEY>\n";
	print "  <BUS_DATE></BUS_DATE>\n";    print "  <BUSDATE_CYCLE_START_TS></BUSDATE_CYCLE_START_TS>\n";    print "  <PARAMS_PATH>C:/gcfr_root/params/</PARAMS_PATH>\n";    print "  <SCRIPTS_PATH>C:/gcfr_root/scripts/</SCRIPTS_PATH>\n";    print "  <LOGS_PATH>C:/gcfr_root/logs/</LOGS_PATH>\n";    print "  <PARAMS_PATH>C:/gcfr_root/params/</PARAMS_PATH>\n";    print "  <LIBS_PATH>c:/gcfr_root/libs/</LIBS_PATH>\n";    print "  <COUNT_SOURCE></COUNT_SOURCE>\n";    print "  <TPTLOGPATH>C:/Program Files (x86)/Teradata/Client/14.00/Teradata Parallel Transporter/logs/</TPTLOGPATH>\n";    print "</GCFR_COMMON_PARAMS>\n";
    return 0;
}
    
sub LogMsg($)
{
###########################################################################
# Purpose:      Print log message
# Params:       message : log message content
###########################################################################
    my $message = shift;
    my $logTime = getTime("time");
    print "$logTime: $message\n";
    return 0;
}

sub LogMsg_sh($)
{
###########################################################################
# Purpose:      Print Shell log message
# Params:       message : log message content
###########################################################################
    my $message = shift;
    my $logTime = getTime("time");
    my $cr = chr(13);
    my $lf = chr(10);
    $message =~ s/($cr|$lf)//g;
    print "$logTime:   $message\n";
    return 0;
}

sub LogMsgLevel($$$)
{
###########################################################################
# Purpose:      Print log message at or belowe the debug level
# Params:       messageLevel : message level
#               debugLevel   : debug level the script is operating under
#               message      : log message content
###########################################################################
    my $messageLevel = shift;
    my $debugLevel = shift;
    my $message = shift;

    if (not defined $debugLevel) {$debugLevel = 6}

    if ($messageLevel <= $debugLevel)
    {
       my $logTime = getTime("time");
       print "$logTime: $message \n";
    }
    return 0;
}

sub ErrExit($)
{
###########################################################################
# Purpose:      Terminate Script with Error Code
# Params:       errorCode : error exit code
###########################################################################
    my $errorCode = shift;
    LogMsg("*** Error, Exit! ***");
    exit $errorCode;
}

sub getTime($)
###########################################################################
# Purpose:      Getting date with time
###########################################################################
{
    my $type = shift;
    use POSIX qw(strftime); 
    my $date = strftime("%m/%d/%Y %H:%M:%S %p", localtime(time)); 
    return $date; 
}

sub Usage_PP()
{
###########################################################################
# Purpose:      Print Usage message
###########################################################################
    print "Usage: perl Run_Process_Pattern.pl [PP] \n";
    print "   Sample:\n";
    print "     perl Run_Process_Pattern.pl Run_Daily_GCFR_all_PP.sh\n";
    return 0;
}

1;
