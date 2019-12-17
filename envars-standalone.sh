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
	"export PATH=$DIR/perl/perls/perl-5.30.1/bin:\$PATH" 
	"export PERL5LIB=$DIR/perl/perls/perl-5.30.1/lib/5.30.1:\$PERL5LIB"
	"export PERL5LIB=$DIR/perl/perls/perl-5.30.1/lib/site_perl/5.30.1:\$PERL5LIB"
	"export PERL5LIB=$DIR/lib:\$PERL5LIB"
)

rm -fr $DIR/.envars
for ((i = 0; i < ${#COMMANDS[@]} + 1; i++))
do
	COMMAND=${COMMANDS[$i]}
	echo $COMMAND
	echo $COMMAND >> $DIR/.envars
	eval $COMMAND 
done

if ! grep -q "~/.envars" $DIR/.bashrc; then 
	echo ". ~/.envars" >> $DIR/.bashrc
fi

