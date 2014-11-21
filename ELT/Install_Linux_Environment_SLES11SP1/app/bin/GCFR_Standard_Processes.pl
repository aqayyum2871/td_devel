#!/usr/bin/perl
############################################################################################################
#<Package>
#<!--
# Purpose:  Teradata GCFR V1 Standard Interface For Perl Script
#
# Params:   XML Parameter File Name, located in '../etc/'
#           XML File maps to Standard 21 GCFR ETL Job Parameters.
#           Please refer to GCFR Development Guide for detail.
#           Sample XML Parameter File:
#               <?xml version="1.0"?>
#               <GCFR_PARAMS>
#                 <TDBSERVER>TDDEV</TDBSERVER>
#                 <TDBUSER>GDE1V</TDBUSER>
#                 <TDBPWD>Teradata123</TDBPWD>
#                 <GCFRDBV>GDEV1V_GCFR</GCFRDBV>
#                 <GCFRDBP>GDEV1P_GCFR</GCFRDBP>
#                 <GCFRDBPROC_PP>GDEV1P_PP</GCFRDBPROC_PP>
#                 <GCFRDBPROC_CP>GDEV1P_CP</GCFRDBPROC_CP>
#                 <GCFRDBPROC_FF>GDEV1P_FF</GCFRDBPROC_FF>
#                 <GCFRDBPROC_BB>GDEV1P_BB</GCFRDBPROC_BB>
#                 <GCFRDBPROC_UT>GDEV1P_UT</GCFRDBPROC_UT>
#                 <PROCESS_NAME></PROCESS_NAME>
#                 <SP_DEBUG_LEVEL>6</SP_DEBUG_LEVEL>
#                 <STREAM_KEY>GCFR_</STREAM_KEY>
#                 <BUS_DATE></BUS_DATE>
#                 <BUSDATE_CYCLE_START_TS></BUSDATE_CYCLE_START_TS>
#                 <SCRIPTS_PATH></SCRIPTS_PATH>
#                 <LOGS_PATH></LOGS_PATH>
#                 <PARAMS_PATH></PARAMS_PATH>
#                 <LIBS_PATH></LIBS_PATH>
#                 <TPTLOGPATH>C:/Program Files (x86)/Teradata/Client/13.10/Teradata Parallel Transporter/logs/</TPTLOGPATH>
#                 <COUNT_SOURCE></COUNT_SOURCE>
#               </GCFR_PARAMS>
#
# Return:   %ERRORLEVEL% to return indication of success of stored procedure (0: Successful; 1: Error)
#
# Important Note:
# A. All Parameters that are common to all Jobs are declared in "GCFR_common_params.xml", that is located in '../etc/'
# B. Parameters in Job File XML will over-ride the parameters in "GCFR_common_params.xml"
# C. Command line parameters will over ride both of these.
#
# Job List:
#               #Job Id List#                       :  #Process Patterns#
#           GCFR_Stream_BusDate_Start               :  Business Date Start CP
#           GCFR_Stream_Start                       :  Stream Start CP
#           GCFR_Stream_End                         :  Stream End CP
#           GCFR_Stream_BusDate_End                 :  Business Date End CP
#           GCFR_StreamSpecBD_Start                 :  Special Business Date Start
#           GCFR_Register_Data_Set_Availability     :  Register Data Set Availability PP
#           GCFR_Register_Data_Set_Loaded           :  Register Data Set Loaded PP
#           GCFR_Register_Data_Set_Exported         :  Register Data Set Exported PP
#           GCFR_TPT_Load                           :  TPT Load PP
#           GCFR_TPT_Load_CLOB                      :  Generate TPT Load Script using new API: GCFR_Load_TPT_CLOB.ddl
#           GCFR_Bkey_PP                            :  Bkey PP
#           GCFR_Bmap_PP                            :  Bmap PP
#           GCFR_Tfm_Full_Apply                     :  Transform Full Apply PP
#           GCFR_Tfm_Delta_Apply                    :  Transform Delta Apply PP
#           GCFR_Tfm_Insert_Append                  :  Transform Transcation PP
#           GCFR_TPT_Export                         :  TPT Export PP
#           GCFR_TPT_Export_CLOB                    :  Generate TPT Export Script using new API: GCFR_Export_TPT_CLOB.ddl
#           BTEQ_Script                             :  Run a user supplied BTEQ script. This is going to be release in future GCFR release
#		 GCFR_Bulk_Register						:  Bulk Register Data Set PP
#		 GCFR_Bulk_Load							:  Bulk Load PP
#		 GCFR_Bulk_Load_CLOB						:  Bulk Load PP (CLOB)
#
#
# How to Execute:
#           perl GCFR_Standard_Processes.pl -job [JobId] -xml [parameter file]
#           Sample:
#                   perl GCFR_Standard_Processes.pl GCFR_Stream_BusDate_Start p_GCFR_Stream_BusDate_Start.xml
#
# Note:     1. Previous versions of this script required the ODBC option "Return Output Parameters as Resultset" to be set
#              this version require it to be cleared.
#              Goto "Control panel"->"administrative tools"->ODBC Data Source Administrator-> [ODBC DSN Name] -> configure -> options.
#              Uncheck "Return Output Parameters as Resultset"
#           2. For Parameter -server, "TDBSERVER" in xml parameter file, it should be the DSN name in ODBC.
#           3. A new entry needs to be added into windows hosts file as format: " [IP Address] [ODBC DSN Name]cop1 ",
#              this is required by load and export module.
#           4. keep the same directory structure
#              [GCFR_ROOT]
#                    |__app\
#                        |__bin\
#                        |    |___GCFR_Common.inc (common lib)
#                        |    |___GCFR_Standard_Processes.wsf (main script file)
#                        |__etc\
#                        |    |___*.xml(process parameter files)
#                        |__lib\
#                             |___UnixUtl\(Unix Utility For Win)
#
# History:
#
# Created By: Rajesh Singh  (rs186006)    2012-12-03
# Modified By: Daniel O'Hara	(DO519239)    2013-06-04
#    Command line options added.
#    Binding used for SP parameters rather than result set.
#    GCFR SP calls moved to a subroutines and GCFR_Stored_Procedure.pl.
#    Removed unnecessary subroutines and scope of variables made local.
#    Changed variable naming standard to one used in gcfr released with 1.01.
#    Added debug level to possible output messages.
#
# Updated By: Bilal Farooq (mf255005)    2013-07-05 
#			Description:		 Added more Command Line arguments and small changes in code
# Updated By: Imad ud din (id255000)	2013-07-31 
#			Description:		Updated the checks for restart steps in GCFR_TPT_Load and GCFR_TPT_Load_CLOB patterns
# Updated By: Bilal Farooq (mf255005)    2013-08-01 
#			Description:		 Added code for pattern GCFR_Register_Data_Set_Exported
# Updated By: Bilal Farooq (mf255005)    2013-11-26 
#			Description:		 Added code for pattern GCFR_Bulk_Register
# Updated By: Imad ud din (id255000)    2013-12-06 
#			Description:		 Updated as per the code revision activity
# Updated By: Imad ud din (id255000)    2013-12-23 
#			Description:		 Updated the restartability check in Bulk Load related to Archiving step
#
# Copyright 2013 by Teradata Corp.
# All Rights Reserved
# TERADATA CONFIDENTIAL INFORMATION
# FOR USE ONLY BY TERADATA ASSOCIATES AND LICENSED CUSTOMERS
#
# Version Information (Do not edit lines below)
# $Date: 2014-10-15 12:28:47 +0200 (Mi, 15 Okt 2014) $
# $Revision: 505 $
# $Author: aw230056 $
#
############################################################################################################
#-->
#!perl
use DBI;
use DBD::ODBC;
#use warnings;
use strict;
require 'GCFR_Common.pl';
require 'GCFR_Stored_Procedure.pl';

# Global variales for parameters with no associated xml parameter
my $jobId;

# Global variables to hold xml parameters some with command line options
my $tdServer;
my $dbUser;
my $dbUserPwd;
my $gcfrDbView;
my $gcfrDbProc;
my $gcfrDbProcPP;
my $gcfrDbProcCP;
my $gcfrDbProcFF;
my $gcfrDbProcUT;
my $gcfrDbProcBB;
my $gcfrProcessName;
my $gcfrProcDebugLevel;
my $gcfrStreamKey;
my $gcfrBusDT;
my $gcfrBusDateCycleStartTs;
my $gcfrScriptsPath;
my $gcfrLogsPath;
my $gcfrParamsPath;
my $gcfrLibsPath;
my $tptLogPath;
my $countSource;

############################
# Define local subroutines #
############################
{
    sub LoadParams($)
    {
        ###########################################################################
        #
        # Purpose:      Parameter Load
        #
        # Params:       xmlParamFile :  Parameter FileName
        #               Parameter File Name, located in '../etc/'
        #
        ###########################################################################
        my $xmlParamFile = shift;

        LogMsgLevel(4,$gcfrProcDebugLevel,"Loading XML Parameters from $xmlParamFile...");

        use XML::Simple;
        use Data::Dumper;

        # Create xml object
        my $xml = new XML::Simple(suppressempty => undef);

        # read Parameter XML file
        if (-e "$xmlParamFile")
        {
            my $data = $xml->XMLin("$xmlParamFile");

            if (not defined($gcfrProcDebugLevel)) {if($gcfrProcDebugLevel = $data->{SP_DEBUG_LEVEL}) {LogMsgLevel(5,$gcfrProcDebugLevel,"  <SP_DEBUG_LEVEL> gcfrProcDebugLevel = $gcfrProcDebugLevel")}}
            if (not defined($tdServer))           {if($tdServer           = $data->{TDBSERVER})      {LogMsgLevel(5,$gcfrProcDebugLevel,"  <TDBSERVER> tdServer = $tdServer")}}
            if (not defined($dbUser))             {if($dbUser             = $data->{TDBUSER})        {LogMsgLevel(5,$gcfrProcDebugLevel,"  <TDBUSER> dbUser = $dbUser")}}
            if (not defined($dbUserPwd))          {if($dbUserPwd          = $data->{TDBPWD})         {LogMsgLevel(5,$gcfrProcDebugLevel,"  <TDBPWD> dbUserPwd = ******")}}
            if (not defined($gcfrDbView))         {if($gcfrDbView         = $data->{GCFRDBV})        {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBV> gcfrDbView = $gcfrDbView")}}
            if (not defined($gcfrDbProc))         {if($gcfrDbProc         = $data->{GCFRDBP})        {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBP> gcfrDbProc = $gcfrDbProc")}}
            if (not defined($gcfrDbProcPP))       {if($gcfrDbProcPP       = $data->{GCFRDBPROC_PP})  {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBPROC_PP> gcfrDbProcPP = $gcfrDbProcPP")}}
            if (not defined($gcfrDbProcCP))       {if($gcfrDbProcCP       = $data->{GCFRDBPROC_CP})  {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBPROC_CP> gcfrDbProcCP = $gcfrDbProcCP")}}
            if (not defined($gcfrDbProcFF))       {if($gcfrDbProcFF       = $data->{GCFRDBPROC_FF})  {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBPROC_FF> gcfrDbProcFF = $gcfrDbProcFF")}}
            if (not defined($gcfrDbProcUT))       {if($gcfrDbProcUT       = $data->{GCFRDBPROC_UT})  {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBPROC_UT> gcfrDbProcUT = $gcfrDbProcUT")}}
            if (not defined($gcfrDbProcBB))       {if($gcfrDbProcBB       = $data->{GCFRDBPROC_BB})  {LogMsgLevel(5,$gcfrProcDebugLevel,"  <GCFRDBPROC_BB> gcfrDbProcBB = $gcfrDbProcBB")}}
            if (not defined($gcfrProcessName))    {if($gcfrProcessName    = $data->{PROCESS_NAME})   {LogMsgLevel(5,$gcfrProcDebugLevel,"  <PROCESS_NAME> gcfrProcessName = $gcfrProcessName")}}
            if (not defined($gcfrStreamKey))      {if($gcfrStreamKey      = $data->{STREAM_KEY})     {LogMsgLevel(5,$gcfrProcDebugLevel,"  <STREAM_KEY> gcfrStreamKey = $gcfrStreamKey")}}
            if (not defined($gcfrScriptsPath))    {if($gcfrScriptsPath    = $data->{SCRIPTS_PATH})   {LogMsgLevel(5,$gcfrProcDebugLevel,"  <SCRIPTS_PATH> gcfrScriptsPath = $gcfrScriptsPath")}}
            if (not defined($gcfrLogsPath))       {if($gcfrLogsPath       = $data->{LOGS_PATH})      {LogMsgLevel(5,$gcfrProcDebugLevel,"  <LOGS_PATH> gcfrLogsPath = $gcfrLogsPath")}}
            if (not defined($gcfrParamsPath))     {if($gcfrParamsPath     = $data->{PARAMS_PATH})    {LogMsgLevel(5,$gcfrProcDebugLevel,"  <PARAMS_PATH> gcfrParamsPath = $gcfrParamsPath")}}
            if (not defined($gcfrLibsPath))       {if($gcfrLibsPath       = $data->{LIBS_PATH})      {LogMsgLevel(5,$gcfrProcDebugLevel,"  <LIBS_PATH> gcfrLibsPath = $gcfrLibsPath")}}
            if (not defined($tptLogPath))         {if($tptLogPath         = $data->{TPTLOGPATH})     {LogMsgLevel(5,$gcfrProcDebugLevel,"  <TPTLOGPATH> tptLogPath = $tptLogPath")}}
            if (not defined($countSource))        {if($countSource        = $data->{COUNT_SOURCE})   {LogMsgLevel(5,$gcfrProcDebugLevel,"  <COUNT_SOURCE> countSource = $countSource")}}
			if (not defined($gcfrBusDT))        {if($gcfrBusDT        = $data->{BUS_DATE})   {LogMsgLevel(5,$gcfrProcDebugLevel,"  <BUS_DATE> gcfrBusDT = $gcfrBusDT")}}
            if (not defined($gcfrBusDateCycleStartTs)) {if($gcfrBusDateCycleStartTs = $data->{BUSDATE_CYCLE_START_TS})
            {LogMsgLevel(5,$gcfrProcDebugLevel,"  <BUSDATE_CYCLE_START_TS> gcfrBusDateCycleStartTs = $gcfrBusDateCycleStartTs")}}

            LogMsgLevel(4,$gcfrProcDebugLevel,"Loading $xmlParamFile Done!")
        }
        else
        {
            LogMsg("Parse $xmlParamFile Failed!");
            ErrExit(1);
        }
    }

}

#############################################################################
# Process command line options using Getopt::Long and LoadParams subroutine #
#############################################################################
{
    # Output version info
    VersionInfo();

    use Getopt::Long;
    LogMsg("Loading Command Line Parameters...");
    my $suppliedARGV = scalar @ARGV;
    my $xmlParamFile;
    my $help = 0;
    if (not GetOptions
    (
        'job=s'          => \$jobId
        ,'xml=s'         => \$xmlParamFile
        ,'server=s'      => \$tdServer
        ,'user=s'        => \$dbUser
        ,'pwd=s'         => \$dbUserPwd
		
		,'gcfrdbview=s'    => \$gcfrDbView
		,'gcfrdbproc=s'    => \$gcfrDbProc
		,'gcfrdbcp=s'      => \$gcfrDbProcCP
		,'gcfrdbpp=s'      => \$gcfrDbProcPP
		,'gcfrdbff=s'      => \$gcfrDbProcFF
		,'gcfrdbbb=s'      => \$gcfrDbProcBB
		,'gcfrdbut=s'      => \$gcfrDbProcUT
        
		,'process=s'      => \$gcfrProcessName
        ,'stream=s'       => \$gcfrStreamKey
		
		,'busdate'        => \$gcfrBusDT
        
		,'timestamp=s'    => \$gcfrBusDateCycleStartTs
        ,'debuglevel=s'   => \$gcfrProcDebugLevel
		
		,'scriptspath=s'  => \$gcfrScriptsPath
		,'logspath=s'     => \$gcfrLogsPath
		,'paramspath=s'   => \$gcfrParamsPath
		,'libspath=s'     => \$gcfrLibsPath
		,'tptlogpath=s'   => \$tptLogPath
		
        ,'countsource=s' => \$countSource
        ,'help|?'        => \$help
    ))
    {
        LogMsg("Invalid Arguments!");
        Usage();
        ErrExit(1);
    }
    if ($suppliedARGV == 2 and scalar @ARGV == 2)
    {
        $jobId        = $ARGV[0];
        $xmlParamFile = $ARGV[1];
    }
    elsif ($help or $suppliedARGV == 0)
    {
        Usage();
        exit 0;
    }
    elsif (scalar @ARGV != 0)
    {
        LogMsg("Invalid Arguments!");
        Usage();
        ErrExit(1);
    }
    elsif (not defined $jobId)
    {
        LogMsg("JobId must be supplied!");
        Usage();
        ErrExit(1);
    }

    # Output command line parameters that have been set
    if (defined $jobId)                   {LogMsgLevel(5,$gcfrProcDebugLevel,"  -job jobId = $jobId")}
    if (defined $xmlParamFile)            {LogMsgLevel(5,$gcfrProcDebugLevel,"  -xml xmlParamFile = $xmlParamFile")}
    if (defined $tdServer)                {LogMsgLevel(5,$gcfrProcDebugLevel,"  -server tdServer = $tdServer")}
    if (defined $dbUser)                  {LogMsgLevel(5,$gcfrProcDebugLevel,"  -user dbUser = $dbUser")}
    if (defined $dbUserPwd)               {LogMsgLevel(5,$gcfrProcDebugLevel,"  -pwd dbUserPwd = $dbUserPwd")}
	
	if (defined $gcfrDbView) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbview gcfrDbView = $gcfrDbView")}
	if (defined $gcfrDbProc) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbproc gcfrDbProc = $gcfrDbProc")}
	if (defined $gcfrDbProcCP) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbcp gcfrDbProcCP = $gcfrDbProcCP")}
	if (defined $gcfrDbProcPP) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbpp gcfrDbProcPP = $gcfrDbProcPP")}
	if (defined $gcfrDbProcFF) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbff gcfrDbProcFF = $gcfrDbProcFF")}
	if (defined $gcfrDbProcBB) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbbb gcfrDbProcBB = $gcfrDbProcBB")}
	if (defined $gcfrDbProcUT) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -gcfrdbut gcfrDbProcUT = $gcfrDbProcUT")}
	
    if (defined $gcfrProcessName)         {LogMsgLevel(5,$gcfrProcDebugLevel,"  -process gcfrProcessName = $gcfrProcessName")}
    if (defined $gcfrStreamKey)           {LogMsgLevel(5,$gcfrProcDebugLevel,"  -stream gcfrStreamKey = $gcfrStreamKey")}
    if (defined $gcfrBusDateCycleStartTs) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -timestamp gcfrBusDateCycleStartTs = $gcfrBusDateCycleStartTs")}
	
	if (defined $gcfrBusDT) {LogMsgLevel(5,$gcfrProcDebugLevel,"  -busdate gcfrBusDT = $gcfrBusDT")}
	
    if (defined $gcfrProcDebugLevel)      {LogMsgLevel(5,$gcfrProcDebugLevel,"  -debuglevel gcfrProcDebugLevel = $gcfrProcDebugLevel")}
	
	if (defined $gcfrScriptsPath)             {LogMsgLevel(5,$gcfrProcDebugLevel,"  -scriptspath gcfrScriptsPath = $gcfrScriptsPath")}
	if (defined $gcfrLogsPath)             {LogMsgLevel(5,$gcfrProcDebugLevel,"  -logspath gcfrLogsPath = $gcfrLogsPath")}
	if (defined $gcfrParamsPath)             {LogMsgLevel(5,$gcfrProcDebugLevel,"  -paramspath gcfrParamsPath = $gcfrParamsPath")}
	if (defined $gcfrLibsPath)             {LogMsgLevel(5,$gcfrProcDebugLevel,"  -libspath gcfrLibsPath = $gcfrLibsPath")}
	if (defined $tptLogPath)             {LogMsgLevel(5,$gcfrProcDebugLevel,"  -tptlogpath tptLogPath = $tptLogPath")}
	
    if (defined $countSource)             {LogMsgLevel(5,$gcfrProcDebugLevel,"  -countsource countSource = $countSource")}

    # Check the suppied jobId is valid
    if ($jobId ne "GCFR_Stream_BusDate_Start"
    and $jobId ne "GCFR_Stream_BusDate_End"
    and $jobId ne "GCFR_Stream_Start"
    and $jobId ne "GCFR_Stream_End"
    and $jobId ne "GCFR_Register_Data_Set_Availability"
    and $jobId ne "GCFR_Register_Data_Set_Loaded"
	and $jobId ne "GCFR_Register_Data_Set_Exported"
    and $jobId ne "GCFR_TPT_Load"
    and $jobId ne "GCFR_TPT_Load_CLOB"
    and $jobId ne "GCFR_Bkey_PP"
    and $jobId ne "GCFR_Bmap_PP"
    and $jobId ne "GCFR_Tfm_Full_Apply"
    and $jobId ne "GCFR_Tfm_Delta_Apply"
    and $jobId ne "GCFR_Tfm_Insert_Append"
    and $jobId ne "GCFR_TPT_Export"
    and $jobId ne "GCFR_TPT_Export_CLOB"
    and $jobId ne "BTEQ_Script"
	and $jobId ne "GCFR_StreamSpecBD_Start"
	and $jobId ne "GCFR_Bulk_Register"
	and $jobId ne "GCFR_Bulk_Load"
	and $jobId ne "GCFR_Bulk_Load_CLOB"
    )
    {
        LogMsg("$jobId is not a Valid JobId!");
        Usage();
        ErrExit(1);
    }

    # Job Start Message
    LogMsg("Job Started. (jobId = $jobId)");

    # Load parameters from user supplied xml parameter file
    if (defined $xmlParamFile) {LoadParams($xmlParamFile)}

    unless ($ENV{"GCFR_GLOBAL_XML_PATH"}) {
        LogMsg("Variable GCFR_GLOBAL_XML_PATH not set!");
        ErrExit(1);
    }

    # Load parameters from manadtory common xml parameter file
    LoadParams($ENV{"GCFR_GLOBAL_XML_PATH"} . "/" . "GCFR_common_params.xml");
    
    if (not defined $gcfrProcDebugLevel) {$gcfrProcDebugLevel = 1}
}


#####################
# Process API Calls #
#####################
{
    ################################
    # Connect to Teradata Database #
    ################################
    LogMsgLevel(4,$gcfrProcDebugLevel,"Connecting Database(DSN = $tdServer, Database = $gcfrDbProc, Uid = $dbUser )...");

    #DBI->trace(DBD::ODBC->parse_trace_flag('odbcconnection'));    # This part gives connection log

    my $dbh = DBI->connect("dbi:ODBC:DSN=$tdServer","$dbUser","$dbUserPwd") or die LogMsg("Cannot connect: $DBI::errstr");
    LogMsgLevel(4,$gcfrProcDebugLevel,"Database connected!");

    
	################################
    # 17. GCFR_StreamSpecBD_Start #
    ################################
    #
    # Increment the Business Date for the Stream to the next date ready for processing
    #
    # Params: $jobId, $gcfrDbProcCP, $gcfrStreamKey, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_StreamSpecBD_Start")
    {
        GCFR_SP($dbh,$gcfrDbProcCP,"GCFR_CP_StreamSpecBD_Start",$gcfrStreamKey,"Numeric",$gcfrBusDT,"Date",$gcfrProcDebugLevel,"Numeric");
    }
	
	
	################################
    # 1. GCFR_Stream_BusDate_Start #
    ################################
    #
    # Increment the Business Date for the Stream to the next date ready for processing
    #
    # Params: $jobId, $gcfrDbProcCP, $gcfrStreamKey, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Stream_BusDate_Start")
    {
        GCFR_SP($dbh,$gcfrDbProcCP,"GCFR_CP_StreamBusDate_Start",$gcfrStreamKey,"Numeric",$gcfrProcDebugLevel,"Numeric");
    }


    ##############################
    # 2. GCFR_Stream_BusDate_End #
    ##############################
    #
    # Finalise the Business Date for the Stream after it has been processed
    #
    # Params: $jobId, $gcfrDbProcCP, $gcfrStreamKey, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Stream_BusDate_End")
    {
        GCFR_SP($dbh,$gcfrDbProcCP,"GCFR_CP_StreamBusDate_End",$gcfrStreamKey,"Numeric",$gcfrProcDebugLevel,"Numeric");
    }


    ########################
    # 3. GCFR_Stream_Start #
    ########################
    #
    # Increment to the next Stream cycle instance
    #
    # Params: $jobId, $gcfrDbProcCP, $gcfrStreamKey, $gcfrBusDateCycleStartTs, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Stream_Start")
    {
        GCFR_SP($dbh,$gcfrDbProcCP,"GCFR_CP_Stream_Start",$gcfrStreamKey,"Numeric",$gcfrBusDateCycleStartTs,"TimeStamp",$gcfrProcDebugLevel,"Numeric");
    }


    ######################
    # 4. GCFR_Stream_End #
    ######################
    #
    # Close the Open Stream cycle instance
    #
    # Params: $jobId, $gcfrDbProcCP, $gcfrStreamKey, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Stream_End")
    {
        GCFR_SP($dbh,$gcfrDbProcCP,"GCFR_CP_Stream_End",$gcfrStreamKey,"Numeric",$gcfrProcDebugLevel,"Numeric");
    }


    ##########################################
    # 5. GCFR_Register_Data_Set_Availability #
    ##########################################
    #
    #Validate source file and Register into GCFR Repository
    #
    # Params: $jobId, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrDbProcBB, $gcfrParamsPath, $gcfrScriptsPath

    if ($jobId eq "GCFR_Register_Data_Set_Availability")
    {
        # Call stored procedure to start or resume file processing
        my ($returnCode, $returnMessage, $processState, $returnParms, $streamKey, $businessDate, $businessDateCycleNum)
            = GCFR_FF_RegisterFile_Initiate($dbh, $gcfrDbProcFF, $gcfrProcessName, 11, $gcfrProcDebugLevel);

        # If process state is less than 3 the file is still in the loading directory and can be processes
        if ($processState < 3)
        {
            # Set process state to 1
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 1, $gcfrProcDebugLevel);

            # Write returnParms into file
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing ParamFile:'$paramFileName");
            WriteFile($paramFileName, $returnParms);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write ParamFile Done.");

            # Run shell script to verify source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Validating Data File..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ut_dataset_verify.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Validate Data File Done.");

            # Set process state to 2
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 2, $gcfrProcDebugLevel);

            # Read out file
            my $outFileName = "$gcfrParamsPath"."$gcfrProcessName".".out";
            my $line  = ReadParamFile($outFileName);
            chomp $line;
            my @paramArray = split(/\Q|/, $line);

            # Ctl file format:
            # FileTimestamp(26)DataStartTimestamp(26)DataEndTimestamp(26)FileQualifier(10)NbrRecords(10)
            #
            # Param File contains:
            # Path|Queue|Data_File_Name|Data_File_Suffix|Ctl_File_Name|Ctl_File_Suffix|Buss_Date|File_Qualifier|BusDt_Cycle_St_TS|ET|UV|Sessions|File_Available|IND
            #
            # DS/out File Contains:
            # Data_File_Name|Ctl_File_Name|BusDt_Cycle_St_TS|File_Qualifier|Total_Records
            #
            # Params for SP: GCFR_FF_File_Register
            # gcfrProcessName, gcfrProcDebugLevel, gcfrStreamKey, businessDate, businessDateCycleNum, busDtCycleStTs,
            # fileQualifier, dataFileName, ctlFileName, extractionDate, extStartTs, extEndTs, toolSessionId, countSource

            my ($returnCode, $returnMessage, $rowCount, $loadingDirectory)
                = GCFR_FF_File_Register($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $streamKey, $businessDate, $businessDateCycleNum,
                    $paramArray[2], $paramArray[3],$paramArray[0], $paramArray[1], undef, undef, undef, undef, $paramArray[4]);

            # Set process state to 3
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 3, $gcfrProcDebugLevel);

            # Run shell script to move verified source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Moving Data File..." );
            $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ut_dataset_move.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."$loadingDirectory";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Move Data File Done.");

            # Set process state to 99 (comlpeted)
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 99, $gcfrProcDebugLevel);
        }
        else
        {
            # If the process is resumed and Reg Source Data PP re-starts at processState 3, then the process failed to move the file
            # to the loading directory and the process can not automatically recover.
            LogMsgLevel(1,$gcfrProcDebugLevel,"Process can not automatically recover from this state.");
            LogMsgLevel(1,$gcfrProcDebugLevel,"It has validated the file but failed moving it to the loading directory.");
            LogMsgLevel(1,$gcfrProcDebugLevel,"The following steps must be carried out manually:");
            LogMsgLevel(1,$gcfrProcDebugLevel,"   a. Verify the file has moved to the loading directory.");
            LogMsgLevel(1,$gcfrProcDebugLevel,"   b. Set process state to 99 by running: CALL $gcfrDbProcBB.GCFR_BB_ProcessIDState_Set('$gcfrProcessName', 99, rowCount).");
        }
    }

    
    ####################################
    # 6. GCFR_Register_Data_Set_Loaded #
    ####################################
    #
    # Validate source file and Register into GCFR Repository
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrStreamKey, $gcfrBusDateCycleStartTs, $countSource

    if ($jobId eq "GCFR_Register_Data_Set_Loaded")
    {
        my ($returnCode,$returnMessage, $processState)
            = GCFR_PP_Reg_DataSet_Loaded($dbh, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrStreamKey, $gcfrBusDateCycleStartTs, undef, undef, undef, $countSource);
    }
	
	######################################
    # 18. GCFR_Register_Data_Set_Exported #
    ######################################
    #
    # Register details in SFE of data-set that is Exported using non-GCFR APIs/Patterns.
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrBusDateCycleStartTs, $countSource

    if ($jobId eq "GCFR_Register_Data_Set_Exported")
    {
        my ($returnCode,$returnMessage, $processState)
            = GCFR_PP_Reg_DataSet_Exported($dbh, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel, $gcfrBusDateCycleStartTs, undef, undef, undef, $countSource);
    }


    #########################
    # 7. GCFR_TPT_Load      #
    # 8. GCFR_TPT_Load_CLOB #
    #########################
    #
    # GCFR_TPT_Load performs the TPT update or load of a Full Image Input to a State (Master) table. 
    # GCFR_TPT_Load_CLOB performs the same function except that, this job supports Large TPT Script Generation -- CLOB
    #
    # Params: $jobId, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $tdServer, $dbUser, $dbUserPwd,
    #         $gcfrParamsPath, $gcfrScriptsPath, $gcfrDbProcBB, $gcfrDbView, $gcfrLogsPath, $gcfrDbProcUT, $tptLogPath

    if ($jobId eq "GCFR_TPT_Load"
    or  $jobId eq "GCFR_TPT_Load_CLOB")
    {
        # Call stored procedure to start or resume TPT load processing
        my ($returnCode, $returnMessage, $processState, $processType) = GCFR_FF_TPTLoad_Initiate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel);

        if ($processState >= 2)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping TPT Script generation..");
        }
        elsif ($jobId eq "GCFR_TPT_Load")
        {
            # Standard TPT load script generation
            # Call Stored Procedure to gererate TPT load script
            my ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText)
                = GCFR_FF_TPTLoad_Generate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $processType, $processState, $tdServer, $dbUser, $dbUserPwd);

            # Write returnParms into file
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing ParamFile: $paramFileName" );
            WriteFile($paramFileName, $returnParms);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write ParamFile Done.");

            # Split returnParms to get Logon Dir
            my @paramArray = split(/\Q|/, $returnParms);

            if ($paramArray[6] ne 20)
            {
                # Write tpt script into file
                my $tptScriptFileName = "$gcfrScriptsPath"."$gcfrProcessName".".tpt";
                LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script File: $tptScriptFileName" );
                WriteFile($tptScriptFileName, $returnScript );
                LogMsgLevel(5,$gcfrProcDebugLevel,"Write TPT Script Done.");
            }

            # Write returnLogonText into file
            my $logonTextFileName = "$paramArray[3]"."$gcfrProcessName"."_dbconnect.tpt";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script Logon File: $logonTextFileName ");
            WriteFile($logonTextFileName, $returnLogonText );
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write Logon Text Done.");
        }
        else
        {
            # Java and CLOB TPT load script generation
            # Run Shell Scrpit named 'gcfr_ff_tptjava_generate.sh' to Generate Large TPT Script and Params File
            # Example: sh gcfr_ff_tptjava_generate.sh LD_786_33_Customer tddemo EDEV1_ETL_USR EDEV1_ETL_USR 4 c:\gcfr_root
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptjava_generate.sh\" "."$gcfrProcessName "."$processState "."$tdServer "."$dbUser "."$dbUserPwd "."$gcfrProcDebugLevel "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."\"$gcfrParamsPath\" "."\"$gcfrLibsPath\" "."\"$gcfrDbView\" "."\"$gcfrDbProcFF\" ";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Calling Shell Script -> $cmdLine ");
            RunCmd($cmdLine,$gcfrProcDebugLevel);
        }

        if ($processState > 3)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping TPT Script Execution...");
        }
        else
        {
            # Run shell script to load source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Loading Data File..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptload_execute.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcFF\" "."\"$tptLogPath\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
        }

        if ($processState >= 4)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping capture load..");
        }
        else
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Capture Load Statistics..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptloadstats_capture.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcBB\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);

            # Read Load stats from stats file
            my $outFileName = "$gcfrScriptsPath"."$gcfrProcessName".".stats";
            my $line = ReadParamFile($outFileName);
            chomp $line;
            my @paramArray = split(/\Q|/, $line);
            
            # Call Stored Procedure
            my ($returnCode, $returnMessage) = GCFR_FF_TPTStats_SetValidate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, @paramArray, undef);
        }

        if ($processState > 4)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping archive Loaded files and TPT log files..." );
        }
        else
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Archive Loaded files and TPT log files..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptload_archive.sh\" "."\"$gcfrParamsPath\" "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcFF\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
						 
        }
		
        # Call Stored Procedure
        my ($returnCode, $returnMessage, $activityCount) = GCFR_FF_TPTLoad_Complete($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel);
    }


    ###################
    # 9. GCFR_Bkey_PP #
    ###################
    #
    # Perform the standard population of a BKey table
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Bkey_PP")
    {
        my ($returnCode,$returnMessage) = GCFR_SP($dbh, $gcfrDbProcPP, "GCFR_PP_BKEY", $gcfrProcessName, "Text", $gcfrProcDebugLevel, "Numeric");
    }


    ####################
    # 10. GCFR_Bmap_PP #
    ####################
    #
    # Perform the standard population of a BMAP table
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Bmap_PP")
    {
        my ($returnCode,$returnMessage) = GCFR_SP($dbh, $gcfrDbProcPP, "GCFR_PP_BMAP", $gcfrProcessName, "Text", $gcfrProcDebugLevel, "Numeric");
    }


    ############################
    # 11. GCFR_Tfm_Delta_Apply #
    ############################
    #
    # Executes the Delta Transform processing pattern
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Tfm_Delta_Apply")
    {
        my ($returnCode,$returnMessage) = GCFR_SP($dbh, $gcfrDbProcPP, "GCFR_PP_TfmDelta", $gcfrProcessName, "Text", $gcfrProcDebugLevel, "Numeric");
    }

    ###########################
    # 12. GCFR_Tfm_Full_Apply #
    ###########################
    #
    # Performs the standard Transformation and Apply processing of a Full Image Input to a State (Master) table
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Tfm_Full_Apply")
    {
        my ($returnCode,$returnMessage) = GCFR_SP($dbh, $gcfrDbProcPP, "GCFR_PP_TfmFull", $gcfrProcessName, "Text", $gcfrProcDebugLevel, "Numeric");
    }

    
    ##############################
    # 13. GCFR_Tfm_Insert_Append #
    ##############################
    #
    # Performs the standard Transformation and Append processing
    #
    # Params: $jobId, $gcfrDbProcPP, $gcfrProcessName, $gcfrProcDebugLevel

    if ($jobId eq "GCFR_Tfm_Insert_Append")
    {
        my ($returnCode,$returnMessage) = GCFR_SP($dbh, $gcfrDbProcPP, "GCFR_PP_TfmTxn", $gcfrProcessName, "Text", $gcfrProcDebugLevel, "Numeric");
    }

    ############################
    # 14. GCFR_TPT_Export      #
    # 15. GCFR_TPT_Export_CLOB #
    ############################
    #
    # GCFR_TPT_Export perform the TPT export Export processing of a table. GCFR_TPT_Export_CLOB performs the same function 
    # except that it supports Large TPT Script Generation -- CLOB
    #
    # Params: $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $tdServer, $dbUser, $dbUserPwd, $gcfrScriptsPath, 
    #         $gcfrLogsPath, $gcfrParamsPath, $gcfrLibsPath, $gcfrDbView, $gcfrDbProcBB, , $gcfrDbProcUT

    if ($jobId eq "GCFR_TPT_Export"
    or  $jobId eq "GCFR_TPT_Export_CLOB")
    {
        # Call Stored Procedure to initiate or resume load
        my ($returnCode, $returnMessage, $processState, $processType) = GCFR_FF_TPTExport_Initiate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel);

        if ($processState > 4)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping FF GCFR_FF_TPTExport_Prepare..." );
        }
        else
        {
            my ($returnCode, $returnMessage) = GCFR_FF_TPTExport_Prepare($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $processType);
        }

        if ($processState > 5)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping TPT Script Generation..." );
        }
        # Standard TPT export script generation
        elsif ($jobId eq "GCFR_TPT_Export")
        {
            my ($returnCode, $returnMessage, $returnParms, $returnScript, $returnLogonText)
                = GCFR_FF_TPTExport_Generate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $processType, $processState, $tdServer, $dbUser, $dbUserPwd);

            # Write returnParms into file
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing ParamFile: $paramFileName ");
            WriteFile($paramFileName, $returnParms );
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write ParamFile Done.");

            # Split returnParms to get Logon Dir
            my @paramArray = split(/\Q|/, $returnParms);

            if ($processType ne 32)
            {
                # Write TPTExport script into file
                my $tptExportScriptFileName = "$gcfrScriptsPath"."$gcfrProcessName".".tpt";
                LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPTExport Script File: $tptExportScriptFileName" );
                WriteFile($tptExportScriptFileName, $returnScript );
                LogMsgLevel(5,$gcfrProcDebugLevel,"Write TPTExport Script Done.");
            }

            # Write returnLogonText into file
            my $logonTextFileName = "$paramArray[3]"."$gcfrProcessName"."_dbconnect.tpt";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script Logon File: $logonTextFileName ");
            WriteFile($logonTextFileName, $returnLogonText );
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write Logon Text Done.");
        }
        # Java and CLOB TPT export script generation
        else
        {
            # Run Shell Scrpit named 'gcfr_ff_tptjava_generate.sh' to Generate Large TPT Script and Params File
            # Example: sh gcfr_ff_tptjava_generate.sh LD_786_33_Customer tddemo EDEV1_ETL_USR EDEV1_ETL_USR 4 c:\gcfr_root
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptjava_generate.sh\" "."$gcfrProcessName "."$processState "."$tdServer "."$dbUser "."$dbUserPwd "."$gcfrProcDebugLevel "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."\"$gcfrParamsPath\" "."\"$gcfrLibsPath\" "."\"$gcfrDbView\" "."\"$gcfrDbProcFF\" ";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Calling Shell Script -> $cmdLine" );
            RunCmd($cmdLine,$gcfrProcDebugLevel);
        }

        if ($processState > 6)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping sh gcfr_ff_tpt_export_execute.sh..." );
        }
        else
        {
            # Run shell script to load source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Exporting Data File..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tpt_export_execute.sh\" "."\"$gcfrParamsPath\" "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcFF\" "."\"$gcfrDbProcBB\" "."\"$tptLogPath\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);

            # Show Load Log
            #my $tptExportLogFileName = "$gcfrLogsPath"."$gcfrProcessName".".log";
            #Call ShowLoadingLogFile($tptExportLogFileName)
        }

        if ($processState > 7)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping sh gcfr_ff_tpt_export_validate.sh..." );
        }
        else
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Capture & Validate Export and archive export log files..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tpt_export_validate.sh\" "."\"$gcfrParamsPath\" "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcBB\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
        }

        # Read parameter from DsFile
        my $outFileName = "$gcfrParamsPath"."$gcfrProcessName".".out";
        my $line  = ReadParamFile($outFileName);
        chomp $line;
        my @paramArray = split(/\Q|/, $line);

        #Call Stored Procedure
        GCFR_FF_TPTExport_Complete($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $paramArray[3], undef);
    }
    
    ###################
    # 16. BTEQ_Script #
    ###################
    #
    # Runs a user supplied BTEQ script, this does not uses the GCFR
    #
    # Params: $jobId, $gcfrScriptsPath, $gcfrProcessName, $tdServer, $dbUser, $dbUserPwd $gcfrScriptsPath $gcfrLogsPath $gcfrProcDebugLevel
    
    if ($jobId eq "BTEQ_Script")
    {
        LogMsgLevel(2,$gcfrProcDebugLevel,"Run user supplied BTEQ script: $gcfrProcessName");
        my $cmdLine = "sh \"$gcfrScriptsPath"."gcfr_bteq_execute.sh\" $gcfrProcessName $tdServer $dbUser \"$dbUserPwd\" \"$gcfrScriptsPath\" \"$gcfrLogsPath\" $gcfrProcDebugLevel";
        RunCmd($cmdLine,$gcfrProcDebugLevel);
    }
  
    ###########################
	# 18. GCFR_Bulk_Register
	###########################
	if ($jobId eq "GCFR_Bulk_Register")
    {
        # Call stored procedure to start or resume file processing
        my ($returnCode, $returnMessage, $processState, $returnParms, $streamKey, $businessDate, $businessDateCycleNum)
            = GCFR_FF_RegisterFile_Initiate($dbh, $gcfrDbProcFF, $gcfrProcessName, 40, $gcfrProcDebugLevel);

        # If process state is less than 3 the file is still in the loading directory and can be processed
        if ($processState < 3)
        {
            # Set process state to 1
            #GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 1, $gcfrProcDebugLevel);

            # Write returnParms into file as .param
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing ParamFile:'$paramFileName");
            WriteFile($paramFileName, $returnParms);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write ParamFile Done.");
			

            my @paramArray = split(/\Q|/, $returnParms);
			my $processType;
			
			# Call Stored Procedure to gererate TPT load script
            my ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText)
                = GCFR_FF_Register_Ctl_Prepare($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, 40, $processState, $tdServer, $dbUser, $dbUserPwd, $paramArray[14]);

            # Write returnParms into file as .param2
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param2";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing ParamFile: $paramFileName" );
            WriteFile($paramFileName, $returnParms);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write ParamFile Done.");

            # Split returnParms to get Logon Dir
            my @paramArray2 = split(/\Q|/, $returnParms);

            
            # Write tpt script into file
            my $tptScriptFileName = "$gcfrScriptsPath"."$gcfrProcessName".".tpt";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script File: $tptScriptFileName" );
            WriteFile($tptScriptFileName, $returnScript );
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write TPT Script Done.");
            
            # Write returnLogonText into file
            my $logonTextFileName = "$paramArray2[3]"."$gcfrProcessName"."_dbconnect.tpt";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script Logon File: $logonTextFileName ");
            WriteFile($logonTextFileName, $returnLogonText );
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write Logon Text Done.");

            # Run shell script to move and load .CTL files
            LogMsgLevel(4,$gcfrProcDebugLevel,"Validating Data File..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_ctl_move_load.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."$processState "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcFF\" "."\"$gcfrDbProcBB\" "."\"$tptLogPath\" ";
						
            RunCmd($cmdLine,$gcfrProcDebugLevel);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Completed moving, loading and archiving .CTL Files.");

            # Set process state to 3
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 3, $gcfrProcDebugLevel);

            
            # Ctl file format:
            # FileTimestamp(26)DataStartTimestamp(26)DataEndTimestamp(26)FileQualifier(10)NbrRecords(10)
            #
            # Param File contains:
            # Path|Queue|Data_File_Name|Data_File_Suffix|Ctl_File_Name|Ctl_File_Suffix|Buss_Date|File_Qualifier|BusDt_Cycle_St_TS|ET|UV|Sessions|File_Available|IND
            #
            # DS/out File Contains:
            # Data_File_Name|Ctl_File_Name|BusDt_Cycle_St_TS|File_Qualifier|Total_Records

			
			# Run shell script to move verified source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Moving Data Files..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_data_files_move.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."$tdServer "."$dbUser "."$dbUserPwd "."$gcfrProcDebugLevel "."\"$gcfrLogsPath\" "."\"$gcfrLibsPath\" "."\"$gcfrDbView\" "."\"$gcfrDbProcFF\" "."\"$gcfrDbProcUT\" "."\"NULL\" ";			
            RunCmd($cmdLine,$gcfrProcDebugLevel);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Move Data Files Done.");

            # Set process state to 99 (comlpeted)
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 99, $gcfrProcDebugLevel);
		}
        elsif ( $processState >= 3)
		{
			# Run shell script to move verified source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Moving Data Files..." );
             my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_data_files_move.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."$tdServer "."$dbUser "."$dbUserPwd "."$gcfrProcDebugLevel "."\"$gcfrLogsPath\" "."\"$gcfrLibsPath\" "."\"$gcfrDbView\" "."\"$gcfrDbProcFF\" "."\"$gcfrDbProcUT\" "."\"NULL\" ";			
            RunCmd($cmdLine,$gcfrProcDebugLevel);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Move Data Files Done.");

            # Set process state to 99 (comlpeted)
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 99, $gcfrProcDebugLevel);
        }
    }
	
	
	###########################
	# 19. GCFR_Bulk_Load
	###########################
	if ($jobId eq "GCFR_Bulk_Load"
    or  $jobId eq "GCFR_Bulk_Load_CLOB")
    {
        # Call stored procedure to start or resume TPT load processing
        my ($returnCode, $returnMessage, $processState, $processType) = GCFR_FF_TPTLoad_Initiate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel);
		my @paramArray;
        if ($processState >= 2)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping TPT Script generation..");
        }
        elsif ($jobId eq "GCFR_Bulk_Load")
        {
            # Standard TPT load script generation
            # Call Stored Procedure to gererate TPT load script
            my ($returnCode,$returnMessage, $returnScript, $returnParms, $returnLogonText)
                = GCFR_FF_TPTLoad_Generate($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, $processType, $processState, $tdServer, $dbUser, $dbUserPwd);

            # Write returnParms into file
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing ParamFile: $paramFileName" );
            WriteFile($paramFileName, $returnParms);
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write ParamFile Done.");

            # Split returnParms to get Logon Dir
            @paramArray = split(/\Q|/, $returnParms);
			
			#LD PARAMS
			#C:/GCFR_ROOT/source_data/786/|CUSTOMER_2011-07-14_000000.000000.txt|CUSTOMER_2011-07-14_000000.000000.ctl|c:/gcfr_root/logon/|loading|archive|13|
			#c:/gcfr_root/logs/LD_786_33_Customer.bad|Ctl_Id|File_Id|Temp_DB|TgtTable|TgtDB|BusDate

			# Write tpt script into file
			my $tptScriptFileName = "$gcfrScriptsPath"."$gcfrProcessName".".tpt";
			LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script File: $tptScriptFileName" );
			WriteFile($tptScriptFileName, $returnScript );
			LogMsgLevel(5,$gcfrProcDebugLevel,"Write TPT Script Done.");

            # Write returnLogonText into file
            my $logonTextFileName = "$paramArray[3]"."$gcfrProcessName"."_dbconnect.tpt";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Writing TPT Script Logon File: $logonTextFileName ");
            WriteFile($logonTextFileName, $returnLogonText );
            LogMsgLevel(5,$gcfrProcDebugLevel,"Write Logon Text Done.");
        }
        else
        {
            # Java and CLOB TPT load script generation
            # Run Shell Scrpit named 'gcfr_ff_tptjava_generate.sh' to Generate Large TPT Script and Params File
            # Example: sh gcfr_ff_tptjava_generate.sh LD_786_33_Customer tddemo EDEV1_ETL_USR EDEV1_ETL_USR 4 c:\gcfr_root
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptjava_generate.sh\" "."$gcfrProcessName "."$processState "."$tdServer "."$dbUser "."$dbUserPwd "."$gcfrProcDebugLevel "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."\"$gcfrParamsPath\" "."\"$gcfrLibsPath\" "."\"$gcfrDbView\" "."\"$gcfrDbProcFF\" ";
            LogMsgLevel(4,$gcfrProcDebugLevel,"Calling Shell Script -> $cmdLine ");
            RunCmd($cmdLine,$gcfrProcDebugLevel);
        }

        if ($processState >= 3)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping TPT Script Execution...");
        }
        else
        {
            # Run shell script to load source data file
            LogMsgLevel(4,$gcfrProcDebugLevel,"Loading Data File..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_tptload_execute.sh\" "."\"$gcfrParamsPath\""." "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcFF\" "."\"$tptLogPath\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
			# Set process state to 3
            GCFR_BB_ProcessIDState_Set($dbh, $gcfrDbProcBB, $gcfrProcessName, 3, $gcfrProcDebugLevel);
        }
		
		################################################################################
		# Call SP named 'GCFR_FF_TPTBulkLoad_CapValid' (Update and Validate Load Stats and SFE)
		################################################################################
		if ($processState >= 4)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping capture and validation of load statistics..." );
        }
		else
		{
			# Read out file
            my $paramFileName = "$gcfrParamsPath"."$gcfrProcessName".".param";
            my $line  = ReadParamFile($paramFileName);
            chomp $line;
            @paramArray = split(/\Q|/, $line);
			
			#LD PARAMS C:/GCFR_ROOT/source_data/786/|CUSTOMER_2011-07-14_000000.000000.txt|CUSTOMER_2011-07-14_000000.000000.ctl|c:/gcfr_root/logon/|loading|archive|
			#13|c:/gcfr_root/logs/LD_786_33_Customer.bad|Ctl_Id|File_Id|Temp_DB|Tgt_Obj|Tgt_DB|BusDt|BDCN|Bus_Dt_Cst|Process_Id|Control File Availability
			
			my ($returnCode,$returnMessage)
                = GCFR_FF_TPTBulkLoad_CapValid($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel, 
				$paramArray[8], $paramArray[9], $paramArray[13], $paramArray[10], $paramArray[11], $paramArray[12], undef, $paramArray[14], "$paramArray[15]", $paramArray[16] );
		}
		
        if ($processState >= 5)
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Skipping archive Loaded files and TPT log files..." );
        }
        else
        {
            LogMsgLevel(4,$gcfrProcDebugLevel,"Archive Loaded files and TPT log files..." );
            my $cmdLine = "sh "."\"$gcfrScriptsPath"."gcfr_ff_data_files_archive.sh\" "."\"$gcfrParamsPath\" "."$gcfrProcessName "."\"$gcfrScriptsPath\" "."\"$gcfrLogsPath\" "."$gcfrProcDebugLevel "."\"$gcfrDbProcUT\" "."\"$gcfrDbProcBB\" ";
            RunCmd($cmdLine,$gcfrProcDebugLevel);
						 
        }
		
        # Call Stored Procedure
        my ($returnCode, $returnMessage, $activityCount) = GCFR_FF_TPTLoad_Complete($dbh, $gcfrDbProcFF, $gcfrProcessName, $gcfrProcDebugLevel);
    }
	#############################
    # Close Database Connection #
    #############################
    LogMsgLevel(4,$gcfrProcDebugLevel,"Disconnecting Database...");
    $dbh->disconnect;
    LogMsgLevel(5,$gcfrProcDebugLevel,"Database disconnected!");
    # Job Complete Message
    LogMsgLevel(1,$gcfrProcDebugLevel,"Job Completed Sucessfully.");
	
}
exit 0;
