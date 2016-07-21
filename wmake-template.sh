#!/bin/bash
set -e

B2D_HOME=C:/"Program Files"/"Boot2Docker for Windows"
VBOX_HOME=C:/"Program Files"/Oracle/VirtualBox
PSQL_BIN=C:/"Program Files"/PostgreSQL/9.4/bin
FILENAME="wmake.sh"

# Call the "real" function
. wmake-main.sh $1 $2

unset B2D_HOME
unset VBOX_HOME
unset PSQL_BIN
unset FILENAME