td_devel
========

Helpful stuff for Teradata Developers

ETL
===
The idea is, to have an empty (new) TMS for ETL purposes
With those two containing packages, you will get
  git (version 2.1.2)
  subversion (version 1.8.10)
  SLJM (version 2.12)
  GCFR (ETL part) (version 1.1.1 including patch 20140703)
installed.
The Linux Environment (folder separation for Develop, Test, Production, ...)
will be set up. Run "setup.sh" for every Environment (free naming)
Unix groups and base environment for SLJM will be created (as well as /etc/skel)

The packages are not supposed to be installed on TPA nodes.
They install new software and libraries (under /usr/local), but one cannot
guarantee, that nothing happens!

I'm not providing software packages here. You need to get them on your own.
