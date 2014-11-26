#include <stdlib.h>
#include <unistd.h>

int main( int argc, char** argv )
{
    // The uid will be uid of original user and the euid will be root (ie 0). Bash
    // scripts don't necessarly use the euid, so we'll setuid full to root.
    // Since the euid is 0, we can setuid to 0.
    //
    // alternativly we can start the script with "#! /bin/bash -p" to force posix mode
    setuid( 0 );

    // shouldn't have to do this, but for consistancy we might as well. And to
    // be sure to be sure
    seteuid( 0 );

    // replace the current programme with this programme, the return value of
    // this C programme is set to the return value of this script.
    // You should use the full path here, since the current directory can be changed by the caller, opening a security risk.
    execl( "/path/to/script.sh", "script.sh", argv[1], 0 );

    // this is never executed.
    return 1;
}
