#!/usr/bin/perl -w

# 
# PURPOSE: THIS INSTALLER ENABLES repo IN TWO MODES: standalone AND dependent. 
#
#
# 1. THE standalone OPTION
#
# COMMAND: ./install.pl standalone
#
# INSTALLATION LOCATION: ANY, E.G.: /repo
#
# DESCRIPTION: 
#
#   THE standalone INSTALLATION DOES THE FOLLOWING:
#
#     - POPULATES THE FOLLOWING git SUBMODULES:
#       - perl SUBMODULE - AN EMBEDDDED PERL EXECUTABLE
#       - lib DIRECTORY SUBMODULES CONTAINING PERL MODULES
#       - package SUBMODULE CONTAINING APP INSTALLERS
#  
#     - COPIES conf/config.yml FROM A TEMPLATE AND PROVIDES VALUES FOR THE FOLLOWING FIELDS:
#       - repo.APPSDIR (E.G.: /repo/apps)
#       - repo.INSTALLDIR (E.G.: /repo)
#       - repo.OPSDIR: (E.G.: /repo/package)
#       - repo.USERDIR: /home
#

#     - RUNS envars-standalone.sh IN ORDER TO AUTOMATICALLY LOAD THE FOLLOWING MODIFIED ENVIRONMENT VARIABLES ON CONNNECTION TO THE CONTAINER:
#       -  THE 'PATH' ENVIRONMENT VARIABLE, ENABLING ACCESS TO: 
#         - THE EMBEDDED PERL EXECUTABLE
#         - THE bin/repo EXECUTABLE
#       -  THE 'PERL5LIB' ENVIRONMENT VARIABLE, ENABLING ACCESS TO: 
#         -  THE PERL MODULES IN THE perl DIRECTORY
#         -  THE PERL MODULES IN THE lib DIRECTORY
#
#
# 2. THE dependent OPTION
#
# COMMAND: ./install.pl dependent
#
# INSTALLATION LOCATION: THE flow APPS DIRECTORY, E.G.: 
#
#   /flow/apps/repo/latest
#
# DESCRIPTION: 
#
#   THE dependent INSTALLATION DOES THE FOLLOWING:
#
#     - POPULATES THE FOLLOWING git SUBMODULES:
#       - package SUBMODULE CONTAINING APP INSTALLERS
#
#     - RUNS envars-dependent.sh IN ORDER TO AUTOMATICALLY LOAD THE FOLLOWING MODIFIED ENVIRONMENT VARIABLES ON CONNNECTION TO THE CONTAINER:
#       -  THE 'PATH' ENVIRONMENT VARIABLE, ENABLING ACCESS TO: 
#         - THE bin/repo EXECUTABLE
#       -  THE 'PERL5LIB' ENVIRONMENT VARIABLE, ENABLING ACCESS TO: 
#         -  THE PERL MODULES IN THE lib DIRECTORY
#
#     - RUNS flow'S lib/Conf/bin/config.pl TO PROVIDE VALUES FOR THE FOLLOWING repo conf/config.yml FIELDS:
#       - repo.APPSDIR (E.G.: /flow/apps)
#       - repo.INSTALLDIR (E.G.: /flow/apps/latest/repo)
#       - repo.OPSDIR: (E.G.: /flow/apps/latest/repo/package)
#       - repo.USERDIR: /home
#
#
# INSTALLER LOGIC: 
#
#   IF PASSED THE standalone OPTION:
#
##    1. INSTALL ALL SUBMODULES
##    2. CHECKOUT OS-SPECIFIC BRANCH OF perl SUBMODULE
##    3. COPY DB TEMPLATE FROM TEMPLATE IF NOT EXISTS
##    4. COPY CONFIG FILE FROM TEMPLATE IF NOT EXISTS
##    5. RUN envars-standalone.sh TO SET ~/.envars FILE
#
#   ELSE IF PASSED THE dependent OPTION:
#
##    1. INSTALL ONLY package SUBMODULE
##    2. COPY DB TEMPLATE FROM TEMPLATE IF NOT EXISTS
##    3. COPY CONFIG FILE FROM TEMPLATE IF NOT EXISTS
##    4. RUN ~/.envars TO SET PATH ONLY IN ~/.envars FILE
#
#

use FindBin qw($Bin);
use File::Copy qw(move);
use File::Path;

#### POPULATE SUBMODULES
my $option = $ARGV[ 0 ];
print "No argument provided (must be either 'dependent' or 'standalone')\n" and exit if not defined $option;
print "Argument not supported: $option (must be either 'dependent' or 'standalone')\n" and exit if not $option =~ /^(dependent|standalone)$/;

#### GET OPERATING SYSTEM
my $os = $^O;

#### CHANGE TO FOLDER OF THIS FILE
chdir( $Bin );

if ( $option eq "standalone" ) {
  
  ##    1. INSTALL ALL SUBMODULES
  updateSubmodules ();
  
  ##    2. CHECKOUT OS-SPECIFIC BRANCH OF perl SUBMODULE
  checkoutPerlBranch( $os );

  ##    3. COPY DB TEMPLATE IF NOT EXISTS
  copyDbFile();

  ##    4. COPY CONFIG FILE FROM TEMPLATE IF NOT EXISTS
  copyConfigFile( $os, $option );

  ##    5. RUN envars-standalone.sh TO SET ~/.envars FILE
  print "\n";
  system( "$Bin/envars-standalone.sh");
}

#### dependent INSTALLATION
elsif ( $option eq "dependent" ) {
  ##    1. INSTALL ONLY package SUBMODULE
  my $command = "git submodule update package";
  print "$command\n";
  system( $command );

  ##    2. COPY DB TEMPLATE IF NOT EXISTS
  copyDbFile();

  ##    3. COPY CONFIG FILE FROM TEMPLATE IF NOT EXISTS
  copyConfigFile( $os, $option );

  ##    4. RUN envars-dependent.sh TO SET ~/.envars FILE
  print "\n";
  system( "$Bin/envars-dependent.sh");

  print "\n";
}

#### SUBROUTINES
sub updateSubmodules {
  print "\nUpdating submodules:\n";
  my $commands = [
    "git submodule update --init --recursive --remote",
  ];
  foreach my $command ( @$commands ) {
    print "$command\n";
    system( $command );
  }
}

sub copyDbFile {
  my $dbtemplate = "$Bin/db/db.sqlite-template";
  my $dbfile = "$Bin/db/db.sqlite";
  if ( -f $dbfile ) {
    print "\nSkipping copy dbfile as file already exists: $dbfile\n";
  }
  else {
    print "\nCopying $dbtemplate to $dbfile\n";
    move( $dbtemplate, $dbfile );
  }  
}

sub copyConfigFile {
  my $os     = shift;
  my $option = shift;

  my $configtemplate = "$Bin/conf/config.yml-template";
  my $configfile = "$Bin/conf/config.yml";
  if ( -f $configfile ) {
    print "\nSkipping copy configfile as file already exists: $configfile\n";
  }
  else {
    print "\nCopying $configtemplate to $configfile\n";
    my $contents = getFileContents( $configtemplate );
    $contents = replaceFields( $os, $option, $contents );
    printFile( $configfile, $contents );
  }  
}
sub printFile {
  my $file      = shift;
  my $contents  = shift;

  open( OUTFILE, ">$file" ) or die "Can't open file: $file\n";
  print OUTFILE $contents;
  close( OUTFILE ) or die "Can't close file: $file\n";
}

sub getFileContents {
  my $file = shift;

  open( INFILE, "<$file" ) or die "Can't open file: $file\n";
  my $temp = $/;
  $/ = undef;
  my $contents = <INFILE>;
  close( INFILE ) or die "Can't close file: $file\n";
  $/ = $temp;

  return $contents;
}

sub replaceFields {
  my $os       = shift;
  my $option   = shift;
  my $contents = shift;

  my $userdir = "/home";
  if ( $os eq "MSWin32" ) {
    $userdir = "C:\Users";
  }
  elsif ( $os eq "darwin" ) {
    $userdir = "/Users"
  }

  my $appsdir = "$Bin/apps";
  print "ORIGINAL appsdir:  $appsdir\n";
  if ( $option eq "dependent" ) {
    # $appsdir = "$Bin/../.." 
    $appsdir =~ s/\/[^\/]+\/?$//;
    $appsdir =~ s/\/[^\/]+\/?$//;
    $appsdir =~ s/\/[^\/]+\/?$//;
  }
  print "FINAL appsdir:  $appsdir\n";

  my $opsdir = "$Bin/package";

  #### REPLACE FIELDS
  $contents =~ s/<APPSDIR>/$appsdir/;
  $contents =~ s/<INSTALLDIR>/$Bin/;
  $contents =~ s/<OPSDIR>/$opsdir/;
  $contents =~ s/<USERDIR>/$userdir/;
  print "FINAL CONTENTS: $contents\n";

  return $contents;
}

sub checkoutPerlBranch {
  my $os = shift;
  my $branch = undef;
  my $archname = undef;
  
  if ( $os eq "darwin" ) {
    print "\nLoading embedded perl branch for OSX\n";
    $branch = "osx10.14.6";
    $archname = "darwin-2level";
  }
  elsif ( $os eq "linux" ) {
    print "Loading perl branch for Linux\n";

    my $osname=`/usr/bin/perl -V  | grep "archname="`;
    # print "osname: $osname\n";
    ($archname) = $osname =~ /archname=([^\-]+)/;
    # print "archname: $archname\n";

    if ( -f "/etc/lsb-release" ) {
      print "Getting Ubuntu version...\n";
      my $version = `cat /etc/lsb-release | grep DISTRIB_RELEASE`;
      $version =~ s/DISTRIB_RELEASE=//;
      $version =~ s/\s+//;
      # print "version: $version\n";
      $branch = "ubuntu$version";
      $branch =~ s/\.//g;
      # print "Branch: $branch\n";
    }
    elsif ( -f "/etc/centos-release" ) {
      print "Getting Centos version...\n";
      my $version = `cat /etc/centos-release | grep "CentOS Linux release"`;
      $version =~ s/CentOS Linux release//;
      $version =~ s/\s+\(Core\)\s*$//;
      $version =~ s/\s+\(Core\)\s*$//;
      $version =~ s/\.\d+$//;
      $version =~ s/\s+//;
      # print "version: $version\n";
      $branch = "centos$version";
      $branch =~ s/\.//g;
      # print "Branch: $branch\n";
    }
    else {
      print "No /etc/lsb-release or /etc/centos-release file found. This Linux flavor is not supported.\n";
    }
  }
  elsif ( $os eq "MSWin32" ) {
    print "Loading embedded perl branch for Windows\n";
    $branch = "MSWin32";
    $archname = "x64-multi-thread";
  }

  if ( $branch and $archname ) {
    print "perl branch: $branch-$archname\n";

    use FindBin qw($Bin);
    my $command = "cd $Bin/perl; git checkout $branch-$archname";
    print "$command\n";
    `$command`;
  }
}  

