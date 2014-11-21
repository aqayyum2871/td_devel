#
# The idea is, to have an empty (new) TMS for ETL purposes
# With those two packages, you will get
#   git (version 2.1.2)
#   subversion (version 1.8.10)
#   SLJM (version 2.12)
#   GCFR (ETL part) (version 1.1.1 including patch 20140703)
# installed.
# The Linux Environment (folder separation for Develop, Test, Production, ...)
# will be set up. Run "setup.sh" for every Environment (free naming)
# Unix groups and base environment for SLJM will be created (as well as /etc/skel)
#
# The packages are not supposed to be installed on TPA nodes.
# They install new software and libraries (under /usr/local), but one cannot
# guarantee, that nothing happens!
#
# Installation procedure:

 1. Copy *.tar.gz to the root user of your Linux Box.
 2. Extract them via "tar zxvf <enter_file_name_here"
 3. change to the new created subfolder:
    3.1. Install_TD_Developers_Package_SLES11SP1
    3.2. run "./install.sh"
    3.3. if everything went well, continue. If not, check and/or contact Support
    3.4. go back one folder level
 4. change to the new created subfolder:
    4.1. Install_Linux_Environment_SLES11SP1
    4.2. run "./setup.sh" (answer some questions)
    4.3. if everything went well, continue. If not, check and/or contact Support
 5. You are finished, now!
 6. Leave the folders if you like (at least Install_Linux_Environment_SLES11SP1)
    You can easily create new Environments if required
 7. An SLJM test Job has created: "Test_Job"
 8. Create users for this environment (optional)
    eg: useradd -c "Testuser" -m -d /home/testuser -g <The_priviously_created_environment> testuser
    This user should be able to run this test job right now!

Attention:
When you install package Install_TD_Developers_Package_SLES11SP1, one of the software components asks for user
action. But interestingly, it doesn't wait. At some time, it looks like, the installation is hanging.
Just hit ENTER to continue with the installation.

Support:
    Andreas Wenzel <andreas.wenzel@teradata.com>
    Ask the real asset owners (SLJM and GCFR) for more (documentation, training, ...)

Bugs:
    If you find any bugs or room for enhancements, please don't hesitate to contact Support!

Additional:
    Documentation to any application delivered or installed by this package is not part
    of this distribution. If it's not included in a sub-package itself, you have to get
    it on your own via asset repository for example:
        https://teradatanet.teradata.com/redir.html?assetId=KA67919
        https://teradatanet.teradata.com/redir.html?assetId=KA66947


Install_Linux_Environment_SLES11SP1
===================================

Install_TD_Developers_Package_SLES11SP1
=======================================
