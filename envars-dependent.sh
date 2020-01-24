#!/bin/bash

# PURPOSE:
#   - CREATE THE FILE ~/.envars CONTAINING ENVIRONMENT VARIABLES
#   - ADD LINE ". ~/envars" TO FILE ~/.bashrc TO LOAD THE ENVIRONMENT VARIABLES ON CONNNECTION TO THE CONTAINER

APPNAME=BIOREPO

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#APPDIR=$( echo ${PWD##*/} | tr a-z A-Z )
APPDIR=${APPNAME}_HOME

declare -a COMMANDS=( 
	"export $APPDIR=$DIR"
	"export PATH=$DIR/bin:\$PATH"
	"export PERL5LIB=$DIR/lib:\$PERL5LIB"
)

ENVARFILE=$DIR/.envars
echo "\nCreating envarfile: $ENVARFILE"
rm -fr $ENVARFILE
for ((i = 0; i < ${#COMMANDS[@]} + 1; i++))
do
	COMMAND=${COMMANDS[$i]}
	echo $COMMAND
	echo $COMMAND >> $ENVARFILE
	eval $COMMAND 
done

if ! grep -q "$DIR/.envars" ~/.bashrc; then 
	echo ". $DIR/.envars" >> ~/.bashrc
fi

