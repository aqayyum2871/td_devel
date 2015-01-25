#!/bin/bash

###############################################################################
#
# Installation routine for SLJM, GCFR and required perl modules
# (c) 2014 Teradata Corp, Andreas Wenzel
#
# Requirements:
# SUSE Linux Enterprise Server 11 Servicepack 1 (SLES11SP1)
#
# Tested on:
#   TDExpress14.10_Sles11_40GB (can be downloaded for free)
#
# Installs:
# Perl modules pre-packaged from SUSE (if not present):
#   perl-XML-NamespaceSupport
#   perl-XML-SAX
#   perl-XML-Simple
#   perl-XML-Parser
# Perl modules installed from source:
#   ExtUtils-MakeMaker-6.98.tar.gz
#   DBI-1.633.tar.gz
#   DBD-ODBC-1.50.tar.gz
# Other packages from SUSE (if not present):
#   tack-5.6-90.55.x86_64.rpm
#   libncurses6-5.6-90.55.x86_64.rpm
#   ncurses-devel-5.6-90.55.x86_64.rpm
# Required Development applications (under /usr/local):
#   openssl-1.0.2.tar.gz
#   apr-1.5.1.tar.bz2
#   apr-util-1.5.4.tar.bz2
#   scons-local-2.3.4.tar.gz (required only by serf-1.3.8.tar.bz2)
#   serf-1.3.8.tar.bz2
#   subversion-1.8.11.tar.bz2 (including sqlite-amalgamation-3080600.zip)
#   curl-7.40.0.tar.bz2
#   git-2.2.2.tar.gz
#
###############################################################################
#
# Changing file permissions because somehow, the installation folders don't
# have proper world permissions.
# This is important. Otherwise, no regular user will be able to execute
# GCFR-Perl-Components
#
###############################################################################
#
# Tested: svn via ssh, https, http protocols
#       : git via ssh, https, http protocols
#
###############################################################################

myinst=$(date +"%Y%m%d-%H%M%S")
mydir=${PWD}

clear

#
# Check, if executed by user root
#
if [ $(id -un) != "root" ]
then
    echo "Please, run as root!"
    exit 99
fi

ERRORCODE=0
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/ssl/lib:${LD_LIBRARY_PATH}
export LD_RUN_PATH=/usr/local/lib:/usr/local/ssl/lib

REQUIRED_RPM_PERL_MODULES="libncurses6-5.6 perl-XML-NamespaceSupport perl-XML-SAX perl-XML-Simple perl-XML-Parser"
UNINSTALL_RPM_PERL_MODULES="perl-DBI"
REQUIRED_SRC_PERL_MODULES="ExtUtils-MakeMaker-7.04.tar.gz DBI-1.633.tar.gz DBD-ODBC-1.50.tar.gz"


#
# Execute command with error check and logging
#
function execute {
    PACKAGE=$1
    STEP=$2
    EXE=$3
    if [ -z ${mydir} ]
    then
        echo "Fatal Error. Variable \${mydir} empty. Definitely not proceeding!"
        exit 1
    fi
    echo ${EXE} >${mydir}/inst.${myinst}/${PACKAGE}.${STEP}.log
    eval ${EXE} 2>&1 | tee -a ${mydir}/inst.${myinst}/${PACKAGE}.${STEP}.log; RC=${PIPESTATUS[0]}
    if [ $RC -ne 0 ]
    then
        echo "Error while executing package: ${PACKAGE} -> ${STEP} -> ${EXE}"
        exit ${ERRORCODE}
    fi
    (( ERRORCODE = ERRORCODE + 1 ))
}

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
            echo "Successfully checked consistency of installation packages"
        else
            echo -e "Could not verify integrity of source packages!\n"
            exit 2
        fi
    else
        echo -e "Could not verify integrity of source packages!\n"
        exit 2
    fi
}

#
# Check version of TTU
# only required for installation of perl modules
#
function check_ttu_version {
    for TTU_VER in 15.00 14.10 14.00 13.10 13.00
    do
        if [ -d "/opt/teradata/client/${TTU_VER}/odbc_64" ]
        then
            INST_ODBC_PATH="/opt/teradata/client/${TTU_VER}/odbc_64/"
            export ODBCINI="/opt/teradata/client/${TTU_VER}/odbc_64/odbc.ini"
            break
        fi
    done

    if [ -z ${INST_ODBC_PATH} ]
    then
        echo -e "Could not find ODBC for Teradata or maybe even TTU!\n"
        exit 3
    else
        echo "Using ODBC in path (${INST_ODBC_PATH})"
    fi
}

#
# Installation routine for perl module
# Argument 1 is the .tar.gz name
# Argument 2 is an optional parameter for the "perl Makefile.pl" command
#
function install_perl_module_from_src {
    PERL_SOFT=$1
    PERL_OPT=$2

    execute "${PERL_SOFT%-*}" "10.unpack" "tar zxvf ${mydir}/${PERL_SOFT}"
    cd ${PERL_SOFT%.tar.gz}
    execute "${PERL_SOFT%-*}" "20.setown" "chown -R root:root ."
    execute "${PERL_SOFT%-*}" "30.configure" "perl Makefile.PL ${PERL_OPT}"
    execute "${PERL_SOFT%-*}" "40.compile" "make"
    execute "${PERL_SOFT%-*}" "50.install" "make install"
    cd ..
}

#
# Install all for GCFR required Perl Modules
#
function install_perl_modules {

    for RPM in ${REQUIRED_RPM_PERL_MODULE}
    do
        rpm -q ${RPM} >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
            if [ -r ${mydir}/${RPM}-*.rpm ]
            then
                rpm -U $(ls -1 ${mydir}/${RPM}-*.rpm)
                if [ $? -ne 0 ]
                then
                    echo -e "Fatal Error while installing rpm ${PRM}!\n"
                    exit 31
                fi
            else
                echo -e "Fatal Error. RPM not found: ${PRM}!\n"
            fi
        fi
    done

    for RPM in ${UNINSTALL_RPM_PERL_MODULE}
    do
        rpm -q ${RPM} >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
            rpm -e ${RPM}
            if [ $? -ne 0 ]
            then
                echo "Fatal Error while un-installing rpm ${PRM}!"
                echo "Maybe dependencies to other packages exist ..."
                exit 31
            fi
        fi
    done

    install_perl_module_from_src ExtUtils-MakeMaker-7.04.tar.gz >ExtUtils-MakeMaker-7.04.instlog
    install_perl_module_from_src Test-Simple-1.001014.tar.gz >Test-Simple-1.001014.instlog
    install_perl_module_from_src DBI-1.633.tar.gz >DBI-1.633.instlog
    install_perl_module_from_src DBD-ODBC-1.50.tar.gz "-o ${INST_ODBC_PATH}" >DBD-ODBC-1.50.instlog

    # Changing permissions because somehow, the installation folders don't have proper world permissions.
    # This is important. Otherwise, no regular user will be able to execute GCFR-Perl-Components
    find /usr/lib/perl5/site_perl/5.10.0/x86_64-linux-thread-multi/ -type d -exec chmod o+rx {} \;

}


#
# START here with the processing
#
check_suse
check_file_integrity
check_ttu_version

#
#
# Start here with extracting tar files, configuring, compiling and installing of source applications
# Installation of RPM packages
# Installation of perl modules via source packages
#
#
mkdir inst.${myinst}
cd inst.${myinst}


execute "openssl" "10.unpack" "tar zxvf ${mydir}/openssl-1.0.2.tar.gz"
cd openssl-1.0.2
execute "openssl" "20.setown" "chown -R root:root ."
execute "openssl" "30.configure" "./config -shared"
execute "openssl" "40.compile" "make"
execute "openssl" "50.install" "make install"
execute "openssl" "60.copycerts" "cp -pRv /etc/ssl/certs/* /usr/local/ssl/certs"
cd ..


execute "apr" "10.unpack" "tar jxvf ${mydir}/apr-1.5.1.tar.bz2"
cd apr-1.5.1
execute "apr" "20.setown" "chown -R root:root ."
execute "apr" "30.configure" "./configure"
execute "apr" "40.compile" "make"
execute "apr" "50.install" "make install"
cd ..


execute "apr-util" "10.unpack" "tar jxvf ${mydir}/apr-util-1.5.4.tar.bz2"
cd apr-util-1.5.4
execute "apr-util" "20.setown" "chown -R root:root ."
execute "apr-util" "30.configure" "./configure --with-apr=/usr/local/apr"
execute "apr-util" "40.compile" "make"
execute "apr-util" "50.install" "make install"
cd ..


execute "scons" "01.mkdir" "mkdir scons"
cd scons
execute "scons" "10.unpack" "tar zxvf ${mydir}/scons-local-2.3.4.tar.gz"
execute "scons" "20.setown" "chown -R root:root ."
if [ ! -d ${HOME}/bin ]
then
    mkdir ${HOME}/bin
fi
if [ $(echo ${PATH} | grep -c ${HOME}/bin) -eq 0 ]
then
    PATH=${PATH}:${HOME}/bin
fi
scons_pwd=${PWD}
cd $HOME/bin
execute "scons" "12.create_ln" "ln -s ${scons_pwd}/scons.py scons"
cd ${mydir}/inst.${myinst}


execute "serf" "10.unpack" "tar jxvf ${mydir}/serf-1.3.8.tar.bz2"
cd serf-1.3.8
execute "serf" "20.setown" "chown -R root:root ."
execute "serf" "40.compile" "scons APR=/usr/local/apr/ APU=/usr/local/apr OPENSSL=/usr/local/ssl"
execute "serf" "50.install" "scons install"
cd ..


execute "subversion" "10.unpack" "tar jxvf ${mydir}/subversion-1.8.11.tar.bz2"
execute "subversion" "11.unzipsqlite" "unzip -x ${mydir}/sqlite-amalgamation-3080600.zip"
execute "subversion" "12.mvsqlite" "mv sqlite-amalgamation-3080600 subversion-1.8.11/sqlite-amalgamation"
cd subversion-1.8.11
execute "subversion" "20.setown" "chown -R root:root ."
execute "subversion" "30.configure" "./configure --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr --with-serf=/usr/local"
execute "subversion" "40.compile" "make"
execute "subversion" "50.install" "make install"
cd ..


execute "curl" "10.unpack" "tar jxvf ${mydir}/curl-7.40.0.tar.bz2"
cd curl-7.40.0
execute "curl" "20.setown" "chown -R root:root ."
execute "curl" "21.copycert" "cp -p ${mydir}/certGithub.pem /usr/local/ssl/certs"
#execute "curl" "30.configure" "./configure --with-ssl=/usr/local/ssl --with-http --with-ftp --with-telnet"
execute "curl" "30.configure" "./configure --with-ssl=/usr/local/ssl --with-http --with-ftp --with-telnet --with-ca-bundle=/usr/local/ssl/certs/certGithub.pem"
execute "curl" "40.compile" "make"
execute "curl" "50.install" "make install"
cd ..


execute "git" "10.unpack" "tar zxvf ${mydir}/git-2.2.2.tar.gz"
cd git-2.2.2
execute "git" "20.setown" "chown -R root:root ."
execute "git" "30.configure" "./configure --with-curl=/usr/local"
execute "git" "40.compile" "make"
execute "git" "50.install" "make install"
cd ..

execute "rpm_inst" "10.tack" "rpm -U ${mydir}/tack-5.6-90.55.x86_64.rpm"
execute "rpm_inst" "10.ncurses-devel" "rpm -U ${mydir}/ncurses-devel-5.6-90.55.x86_64.rpm"

install_perl_modules

echo "Teradata Developer's Package installed successfully!"
