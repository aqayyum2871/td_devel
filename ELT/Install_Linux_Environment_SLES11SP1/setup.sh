#!/bin/bash

###############################################################################
#
# Installation routine for SLJM, GCFR and (probably) required perl modules
# (c) 2014 Teradata Corp, Andreas Wenzel
#
# Requirements:
# SUSE Linux Enterprise Server 11 Servicepack 1 (SLES11SP1)
#
# Tested on:
#   TDExpress14.10_Sles11_40GB (can be downloaded for free)
#
# Installs:
#   GCFR 1.1.1 from 20140512 including patch from 20140703
#   SLJM 2.12
#
# Manipulates the three Perl files for GCFR:
#   GCFR_Common.pl
#   GCFR_Standard_Processes.pl
#   GCFR_Stored_Procedure.pl
# those get changed via "dos2unix" to convert character encoding and type of
# line break. Additionally, the interpreter for perl as a keyword gets inserted
# as first line(!!!). With that change, invocation of "perl GCFR_*.pl" is not
# required. It is sufficient to execute "GCFR_*.pl".
#
###############################################################################
#
# A test and demo SLJM Job can be found in the "jobs" folder named "Test_Job"
#
# Remember, SLJM requires the user to be in the correct primary group to set
# the environment properly during login. It can be changed later, anyway.
#
###############################################################################

myinst=$(date +"%Y%m%d-%H%M%S")
mydir=${PWD}

clear

#set trap

INST_SLJM_SOFT="sljm_v2.12.tar.gz"

#
# Check, if executed by user root
#
if [ $(id -un) != "root" ]
then
    echo "Please, run as root!"
    exit 99
fi

#
# Check if supported Linux Distribution and version
#
function check_suse {
    ERROR=0
    if [ -r /etc/SuSE-brand ]
    then
        if [ $(grep -c "^SLES$" /etc/SuSE-brand) -ne 1 ]
        then
            echo "System is SuSE, but not SLES! Continuing could harm your system!"
            while true
            do
                echo -n "Do you want to continue? Not recommended! (y/n) "
                read INPUT
                if [[ "${INPUT}" = "y" || "${INPUT}" = "yes" ]]
                then
                    CONTINUE=y
                    (( ERROR = ERROR + 1 ))
                    break
                elif [[ "${INPUT}" = "n" || "${INPUT}" = "no" ]]
                then
                    CONTINUE=n
                    break

                fi
            done
            if [ "${CONTINUE}" = "n" ]
            then
                echo -e "Installation aborted on user request!\n"
                exit 1
            fi
        fi
        if [ $(grep -c "^VERSION = 11$" /etc/SuSE-release) -ne 1 ]
        then
            echo "System is not SLES11! Continuing could harm your system!"
            while true
            do
                echo -n "Do you want to continue? Not recommended! (y/n) "
                read INPUT
                if [[ "${INPUT}" = "y" || "${INPUT}" = "yes" ]]
                then
                    CONTINUE=y
                    (( ERROR = ERROR + 1 ))
                    break
                elif [[ "${INPUT}" = "n" || "${INPUT}" = "no" ]]
                then
                    CONTINUE=n
                    break

                fi
            done
            if [ "${CONTINUE}" = "n" ]
            then
                echo -e "Installation aborted on user request!\n"
                exit 1
            fi
        fi
        if [ $(grep -c "^PATCHLEVEL = 1$" /etc/SuSE-release) -ne 1 ]
        then
            echo "System is not SLES11SP1! Continuing could harm your system!"
            while true
            do
                echo -n "Do you want to continue? Not recommended! (y/n) "
                read INPUT
                if [[ "${INPUT}" = "y" || "${INPUT}" = "yes" ]]
                then
                    CONTINUE=y
                    (( ERROR = ERROR + 1 ))
                    break
                elif [[ "${INPUT}" = "n" || "${INPUT}" = "no" ]]
                then
                    CONTINUE=n
                    break

                fi
            done
            if [ "${CONTINUE}" = "n" ]
            then
                echo -e "Installation aborted on user request!\n"
                exit 1
            fi
        fi
        if [ ${ERROR} -eq 0 ]
        then
            SUSE="Found supported and tested SuSE Distribution!"
        else
            echo "Untested Linux Distribution found! Continuing with warnings!"
            SUSE="Untested Linux Distribution found! Continuing with warnings!"
        fi
    else
        echo -e "Unsupported Linux Distribution found!\n"
        exit 1
    fi
}

#
# Check integrity (md5sum) of source packages
#
function check_file_integrity {
    if [[ -s md5sum.txt && -r md5sum.txt ]]
    then
        md5sum -c md5sum.txt >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
            echo -e "\nSuccessfully checked consistency of installation packages"
        else
            echo -e "\nCould not verify integrity of source packages (md5sum.txt)!\n"
            exit 2
        fi
    else
        echo -e "\nCould not verify integrity of source packages (md5sum.txt)!\n"
        exit 2
    fi
}

#
# Check Linux/Unix group
#
function check_unix_groups {
    if [ $(cut -f1 -d\: /etc/group | grep -c "^${INST_ENV}$") -eq 1 ]
    then
        echo "Unix group ${INST_ENV} already exists. No change!"
    else
        echo "New Unix group ${INST_ENV} will be created!"
    fi

    if [ $(cut -f1 -d\: /etc/group | grep -c "^${INST_ENV}_Delv$") -eq 1 ]
    then
        echo "Unix group ${INST_ENV}_Delv already exists. No change!"
    else
        echo "New Unix group ${INST_ENV}_Delv will be created!"
    fi
}

#
# Check if file already exists in target, and create backup version if exists
#
function backup_existing_file {
    FROM_FILE=$1
    if [ -f "/${FROM_FILE}" ]
    then
        cp -pR "/${FROM_FILE}" "${FROM_FILE}.${myinst}"
        (( BACKUPS = BACKUPS + 1 ))
    fi
}

#
# Compile and prepare SLJM in app folder from GCFR
#
function compile_and_prepare_sljm {

    tar zxf ../${INST_SLJM_SOFT}
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error extracting SLJM package.\n"
        exit 15
    fi
    cd sljm
    chown -R root *
    touch *.c *.h
    make -f sljm_linux.mak >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while compiling SLJM!\n"
        exit 14
    fi
    make -f sljm_linux.mak purge >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while purging source files from SLJM!\n"
        exit 15
    fi
    cd ..
    mkdir -p "${INST_DWH_BASE#/}/${INST_ENV}/app/bin"
    mv sljm/* "${INST_DWH_BASE#/}/${INST_ENV}/app/bin"
    rmdir sljm
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while removing SLJM folder. Is supposed to be empty.\n"
        exit 16
    fi
    echo "export LOGON=\${HOME}/.logon" >"${INST_DWH_BASE#/}/${INST_ENV}/sljm.env"
    echo "export TDPID=\"127.0.0.1\""  >>"${INST_DWH_BASE#/}/${INST_ENV}/sljm.env"

    # Create folders
    [ -d ${mydir}/inst.${myinst}/${INST_DWH_BASE#/}/${INST_ENV}/jobs ] || mkdir ${mydir}/inst.${myinst}/${INST_DWH_BASE#/}/${INST_ENV}/jobs
    [ -d ${mydir}/inst.${myinst}/${INST_DWH_BASE#/}/${INST_ENV}/logs ] || mkdir ${mydir}/inst.${myinst}/${INST_DWH_BASE#/}/${INST_ENV}/logs
    [ -d ${mydir}/inst.${myinst}/${INST_DWH_BASE#/}/${INST_ENV}/env ]  || mkdir ${mydir}/inst.${myinst}/${INST_DWH_BASE#/}/${INST_ENV}/env

}

#
# Unpack and prepare GCFR
#
function prepare_gcfr {

    unzip -xo ../GCFR_V1.1.1_ETL_Work_20140512.zip >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while uncompressing GCFR_V1.1.1_ETL_Work_20140512.zip\n"
        exit 16
    fi
    unzip -xo ../GCFR_Release_1.1.1_patch_20140703.zip >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while uncompressing GCFR_Release_1.1.1_patch_20140703.zip\n"
        exit 17
    fi
    rm -rf GCFR_DDL_Code GCFR_V1.1.1_Metadata_Registration_Tool_20140703.zip GCFR_Software_Release_Note_For_Patch_20140703.pdf
    mv GCFR_ETL_Work/* "${INST_DWH_BASE#/}/${INST_ENV}"
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while preparing GCFR folders!\n"
        exit 18
    fi
    rmdir GCFR_ETL_Work
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while removing GCFR folder. Is supposed to be empty!\n"
        exit 19
    fi

    mkdir "${INST_DWH_BASE#/}/${INST_ENV}"/logon
}

#
# Questions for the user
#
function ask_installation_questions {
    while true
    do
        echo -ne "\nWhat is your existing SLJM/GCFR base folder (/DWH)? "
        read INPUT
        if [ -z ${INPUT} ]
        then
            INPUT=/DWH
        fi
        if [[ -d "${INPUT}" && -w "${INPUT}" ]]
        then
            INST_DWH_BASE="${INPUT}"
            break
        else
            echo "Error accessing folder \"${INPUT}\" to write!"
            echo "Try another one, or create it in an additional session!"
        fi
    done

    while true
    do
        echo -ne "\nWhat is your Environment name (DEV1, TST1, PRD, ...)? "
        read INPUT
        if [ -z ${INPUT} ]
        then
            true
        else
            if [ -d "${INST_DWH_BASE}/${INPUT}" ]
            then
                export INST_ENV="${INPUT}"
                while true
                do
                    echo -ne "\nFolder already exists. Choose another one? (y/n) "
                    read INPUT
                    if [[ "${INPUT}" = "y" || "${INPUT}" = "yes" ]]
                    then
                        unset INST_ENV
                        break
                    elif [[ "${INPUT}" = "n" || "${INPUT}" = "no" ]]
                    then
                        break
                    fi
                done
            else
                export INST_ENV="${INPUT}"
                break
            fi

            [ "${INST_ENV}" = "" ] || break
        fi
    done
}


#
# Show installation summary and ask if continue
#
function installation_summary {
    echo -e "\nInstallation summary. Read carefully!"
    echo ${SUSE}

    echo "No Installation of perl modules! Hopefully, they're already installed properly!"

    echo "DWH Base folder: ${INST_DWH_BASE}"
    echo "Environment    : ${INST_ENV}"
    if [ -d "${INST_DWH_BASE}/${INST_ENV}" ]
    then
        echo "Environment folder ${INST_DWH_BASE}/${INST_ENV} will be repopulated!"
    else
        echo "Environment folder ${INST_DWH_BASE}/${INST_ENV} will be created!"
    fi
    check_unix_groups

    while true
    do
        echo -ne "\nDo you want to continue? (y/n) "
        read INPUT
        if [[ "${INPUT}" = "y" || "${INPUT}" = "yes" ]]
        then
            break
        elif [[ "${INPUT}" = "n" || "${INPUT}" = "no" ]]
        then
            exit 6
        fi
    done
}

#
# create Demo/Test SLJM job
#
function create_sljm_job {
    SLJM_JOB="Test_Job"
    [ -d "${INST_DWH_BASE#/}/${INST_ENV}/jobs/${SLJM_JOB}" ] || mkdir "${INST_DWH_BASE#/}/${INST_ENV}/jobs/${SLJM_JOB}"
    [ -d "${INST_DWH_BASE#/}/${INST_ENV}/logs/${SLJM_JOB}" ] || mkdir "${INST_DWH_BASE#/}/${INST_ENV}/logs/${SLJM_JOB}"
    {
        echo "export ETC=${INST_DWH_BASE}/${INST_ENV}/jobs/${SLJM_JOB}"
        echo "export LOGFILE=${INST_DWH_BASE}/${INST_ENV}/logs/${SLJM_JOB}/${SLJM_JOB}.log"
        echo "export TMPDIR=${INST_DWH_BASE}/${INST_ENV}/logs/${SLJM_JOB}"
        echo "#"
        echo "# The following is from the documentation"
        echo "#"
        echo "# DAT .............. default: ETC content; directory path holding data files"
        echo "# WORK ............. default: ETC content; path to working directory"
        echo "# DONESCRIPT ....... default: none; path to script to be executed upon successful job termination"
        echo "# WARNSCRIPT ....... default: none; path to script to be executed upon successful job termination with"
        echo "#                    warnings; if undefined FAILSCRIPT is executed instead"
        echo "# FAILSCRIPT ....... default: none; path to scripts to be executed upon job termination on errors"
        echo "# EXITSCRIPT ....... default: none; path to scripts to be executed upon any job termination"
        echo "# STARTSCRIPT ...... default: none; path to scripts to be executed upon any job start"
        echo "# STEPFAILSCRIPT ... default: none; path to scripts to be executed immediately after step failure"
        echo "# SLJMDBLOG......... default: none; path to an event log file (see 'Event Log' below)"
        echo "# SLJMPROCLIMIT .... default: none; defines maximum number of parallel running processes (job steps)"
        echo "# SLJMCOLORS ....... default: none; used to define alternate j monitor color schema"
        echo "# The next three lines are just used in wrapper scripts coming with SLJM. GCFR does not use them"
        echo "# TMPDIR ........... default: ETC content; directory path for Bteq/Mload/Fload/Fexp output files"
        echo "# MAX_SESSIONS ..... default: none; maximum number of sessions used by Mload and Fload"
        echo "# MLOAD_CHARSET .... default: none; defines mload client character set (-c option)"
    } >"${INST_DWH_BASE#/}/${INST_ENV}/jobs/${SLJM_JOB}/${SLJM_JOB}.env"
    echo "true" >"${INST_DWH_BASE#/}/${INST_ENV}/jobs/${SLJM_JOB}/${SLJM_JOB}.job"
    touch "${INST_DWH_BASE#/}/${INST_ENV}/logs/${SLJM_JOB}/${SLJM_JOB}.log"
    {
        cd "${INST_DWH_BASE#/}/${INST_ENV}/env"
        ln -s "../jobs/${SLJM_JOB}/${SLJM_JOB}.env" "${SLJM_JOB}.env"
        cd - >/dev/null
    }
}

#
# Installation of SLJM/GCFR in temp install folder
# Eventual creation of Environment group
# Eventual installation of Perl Modules
#
function installation_preparation {

    prepare_gcfr

    compile_and_prepare_sljm

    #
    # Create new Unix groups
    #
    if [ $(cut -f1 -d\: /etc/group | grep -c "^${INST_ENV}$") -eq 0 ]
    then
        groupadd ${INST_ENV}
        if [ $? -eq 0 ]
        then
            echo "Created new Unix group ${INST_ENV}"
        else
            echo -e "Fatal Error while creating new Unix group ${INST_ENV}\n"
            exit 11
        fi
    fi
    if [ $(cut -f1 -d\: /etc/group | grep -c "^${INST_ENV}_Delv$") -eq 0 ]
    then
        groupadd ${INST_ENV}_Delv
        if [ $? -eq 0 ]
        then
            echo "Created new Unix group ${INST_ENV}_Delv"
        else
            echo -e "Fatal Error while creating new Unix group ${INST_ENV}_Delv\n"
            exit 12
        fi
    fi

    #
    # Set user, group and permission
    #
    chown -R root:${INST_ENV} "${INST_DWH_BASE#/}/${INST_ENV}"
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while changing file ownerships and group\n"
        exit 12
    fi

    chmod -R o-rwx *
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while changing file permissions\n"
        exit 13
    fi

    # Create identical folder structure in temporary install dir
    mkdir -p etc/profile.d etc/skel "${INST_DWH_BASE#/}/${INST_ENV}"

    # Escape slashes for sed command
    export SED_INST_DWH_BASE=$(echo ${INST_DWH_BASE} | sed -e 's/[]\/$*.^|[]/\\&/g')
    export SED_INST_ODBC_PATH=$(echo ${INST_ODBC_PATH} | sed -e 's/[]\/$*.^|[]/\\&/g')

    # Copy and eventually manipulate skripts to temporary install dir
    sed "s/INST_DWH_BASEDIR/${SED_INST_DWH_BASE}/" <../sljm/conf/etc/profile.d/sljm.sh >etc/profile.d/sljm.sh
    cp -p ../sljm/conf/etc/skel/user_profile.txt etc/skel/.profile
    sed "s/INST_ODBC_LIB_PATH/${SED_INST_ODBC_PATH}/" <../sljm/conf/group_profile.txt >"${INST_DWH_BASE#/}/${INST_ENV}/.profile"

    # Copy customized scripts and additional GCFR wrapper for SLJM
    for XBIN in $(ls -1 ../app/bin)
    do
        cp -p ../app/bin/${XBIN} "${INST_DWH_BASE#/}/${INST_ENV}/app/bin"
        if [ $? -ne 0 ]
        then
            echo -e "Fatal Error while copying scripts to app/bin\n"
            exit 13
        fi
    done
}


#
# Set individual privilages and groups on folders/files
#
function set_special_privileges {
    chgrp -R "${INST_ENV}" "${INST_DWH_BASE#/}/${INST_ENV}" "${INST_DWH_BASE#/}/${INST_ENV}/.profile"
    chmod -R 750           ${INST_DWH_BASE#/}/${INST_ENV}
    chmod -R 770           ${INST_DWH_BASE#/}/${INST_ENV}/{app/etc,logs,params,jobs,env,scripts,logon}
    chmod    660           ${INST_DWH_BASE#/}/${INST_ENV}/{jobs,logs}/*/*
    chmod    775           ${INST_DWH_BASE#/}/${INST_ENV}/{source_data,export_data}
    chmod    750           ${INST_DWH_BASE#/}/${INST_ENV}/scripts/*
    chmod    755           ${INST_DWH_BASE#/}/${INST_ENV}
    chmod    a+r           etc/skel/.profile etc/profile.d/sljm.sh
    chmod    o+rx          etc/skel etc/profile.d
    chmod    640           ${INST_DWH_BASE#/}/${INST_ENV}/sljm.env
    for FO in "${INST_DWH_BASE#/}/${INST_ENV}/jobs" "${INST_DWH_BASE#/}/${INST_ENV}/logs" \
              "${INST_DWH_BASE#/}/${INST_ENV}/source_data" "${INST_DWH_BASE#/}/${INST_ENV}/export_data"
    do
        echo "Setting the following ACLs: setfacl -dm g::rwx ${FO}"
        setfacl -dm g::rwx ${FO}
    done
    echo "This guarantees, newly created folders will be group writeable as well!"
}


#
# Startup with some information
#
echo "Welcome to the installation routine for GCFR/SLJM"
echo "You will be asked some questions. Some are just yes or no, others are with real values."
echo "For yes/no, answers only (y, yes, n, no) are allowed!"
echo "For real values, defaults maybe present in paranthesis!"
echo "All required software packages dependant for SLJM and/or GCFR must have been"
echo "installed with Package Install_TD_Developers_Package_SLES11SP1"

#
# Continue with important checks
#
check_suse
check_file_integrity

#
# Questions for the user
#
ask_installation_questions

#
# Show installation summary and ask if continue
#
installation_summary

#
# Installation of SLJM/GCFR in temp install folder
# Eventual creation of Environment group
# Eventual installation of Perl Modules
#
mkdir inst.${myinst}
cd inst.${myinst}

# Create new root folder structure in temporary installation folder
mkdir -p "${INST_DWH_BASE#/}/${INST_ENV}"

installation_preparation
create_sljm_job

#
# Some manipulations on Perl files
#
cd "${INST_DWH_BASE#/}/${INST_ENV}"/app/bin
for FI in GCFR_*.pl
do
    dos2unix ${FI} >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo -e "Fatal Error while changing group of ${FI}\n"
        exit 19
    fi

    if [ $(awk 'BEGIN {out=0} NR == 1 && /^\#\!\/usr\/bin\/perl/ {out=1} END {print out}' ${FI}) -ne 1 ]
    then
        mv ${FI} ${FI}.tmp
        {
            echo "#!/usr/bin/perl"
            cat ${FI}.tmp
        } >${FI}
        rm ${FI}.tmp
    fi
done

cd ${mydir}/inst.${myinst}

set_special_privileges

#
# Before copying files to install folder, ask
# At this point, Unix group is created, Perl Modules are installed, and SLJM and GCFR are prepared in subfolder inst.<timestamp>
#
while true
do
    echo -ne "\nFiles have been prepared in inst.${myinst}. Check in another windows.\n"
    echo "This is the last step now."
    echo -n "Do you want to install them in real install folders? (y/n) "
    read INPUT
    if [[ "${INPUT}" = "y" || "${INPUT}" = "yes" ]]
    then
        break
    elif [[ "${INPUT}" = "n" || "${INPUT}" = "no" ]]
    then
        exit 6
    fi
done

#
# Create backup for files which already exist in target
#
BACKUPS=0
for FILE1 in $(find . \( -type f -o -type l \))
do
    FILE=${FILE1#*/}
    backup_existing_file "${FILE}"
done

#
# Copy to install directory
#
for OBJ in $(find . \( -type d -o -type f -o -type l \))
do
    [ "${OBJ}" = "." ] && continue

    if [ -e /${OBJ} ]
    then
        # exists
        if [ -d ${OBJ} ]
        then
            # Is directory
            if [ ! -d /${OBJ} ]
            then
                # Target exists and is not a directory
                echo "Directory mismatch (do nothing): ${OBJ} -> /${OBJ}"
            fi
        elif [ -f ${OBJ} ]
        then
            # Is regular file
            if [ ! -f /${OBJ} ]
            then
                # Target exists and is not a file
                echo "File mismatch (do nothing): ${OBJ} -> /${OBJ}"
            else
                cp -pR ${OBJ} /${OBJ}
            fi
        elif [ -h ${OBJ} ]
        then
            # Is symbolic link
            if [ ! -h /${OBJ} ]
            then
                # Target exists and is not a symbolic link
                echo "Symbolic link mismatch (do nothing): ${OBJ} -> /${OBJ}"
            fi
        fi
    else
        # not exists
        cp -pR ${OBJ} /${OBJ}
    fi
done

if [ ${BACKUPS} -gt 0 ]
then
    echo -e "\nBackup copies of ${BACKUPS} files have been made."
    echo "You can find them with \"find ${mydir}/inst.${myinst} -type f -name \*.${myinst}\""
fi

echo -e "\nInstallation of Environment ${INST_ENV} successful!"
echo -e "Don't forget to create/assign users to that Environment with primary group!\n"
