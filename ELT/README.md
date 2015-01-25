Idea
====
The idea is, to have an empty (new) TMS for ETL purposes.
With those two packages, you will get

* git (version 2.2.2)
* subversion (version 1.8.11)
* SLJM (version 2.12)
* GCFR (ETL part) (version 1.1.1 including patch 20140703)

installed.

The Linux Environment (folder separation for Develop, Test, Production, ...)
will be set up. Run "setup.sh" for every Environment (free naming)
Unix groups and base environment for SLJM will be created (as well as /etc/skel)

The packages are not supposed to be installed on TPA nodes.
They install new software and libraries (under /usr/local), but one cannot
guarantee, that nothing happens!

Install_Linux_Environment_SLES11SP1
===================================
If you are an Teradata Employee, then you know how to get those packages:
* SLJM (AssetID: KA66947)
* GCFR (AssetID: KA67919)

If you don't know, what SLJM or GCFR is, then you don't need that package.

Install_TD_Developers_Package_SLES11SP1
=======================================
The main goal for this package is the installation of this packages:
* git (version 2.2.2)
* subversion (version 1.8.11)

Also, there are some packages included, which are required by SLJM or GCFR!

You need to have an Account at Novel, to be able to download those official RPMs for SLES11SP1:

* tack-5.6-90.55.x86_64.rpm
* libncurses6-5.6-90.55.x86_64.rpm
* ncurses-devel-5.6-90.55.x86_64.rpm
* perl-XML-NamespaceSupport-1.09-1.22.x86_64.rpm
* perl-XML-Parser-2.36-1.18.x86_64.rpm
* perl-XML-SAX-0.96-2.7.x86_64.rpm
* perl-XML-Simple-2.18-1.15.x86_64.rpm

The following packages are available for free download:

* apr-1.5.1.tar.bz2 (http://artfiles.org/apache.org/apr/apr-1.5.1.tar.bz2)
* apr-util-1.5.4.tar.bz2 (https://apr.apache.org/download.cgi)
* curl-7.38.0.tar.bz2 (http://curl.haxx.se/download.html)
* DBD-ODBC-1.50.tar.gz (https://metacpan.org/pod/DBD::ODBC)
* DBI-1.631.tar.gz (https://metacpan.org/pod/DBI)
* ExtUtils-MakeMaker-6.98.tar.gz (https://metacpan.org/pod/ExtUtils::MakeMaker)
* git-2.2.2.tar.gz (https://www.kernel.org/pub/software/scm/git/)
* openssl-1.0.2.tar.gz (https://www.openssl.org/source/)
* scons-local-2.3.3.tar.gz (http://www.scons.org/download.php)
* serf-1.3.7.tar.bz2 (http://www.linuxfromscratch.org/blfs/view/svn/basicnet/serf.html)
* sqlite-amalgamation-3080600.zip (http://www.sqlite.org/download.html)
* subversion-1.8.11.tar.bz2 (https://subversion.apache.org/download/)
* Test-Simple-1.001006.tar.gz (http://search.cpan.org/dist/Test-Simple/lib/Test/Builder.pm)

After writing this document, some packages above might be outdated.
I'll try to keep up with development. If anyone can support me with that, it would be highly appreciated.
