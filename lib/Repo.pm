use MooseX::Declare;
use Method::Signatures::Simple;

=head2

PACKAGE    Repo

PURPOSE

  Automated package installer and manager
  
=cut

use strict;
use warnings;
use Carp;

class Repo with Util::Logger {

#### USE LIB
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use File::Path;

#### INTERNAL MODULES
use DBase::Factory;
use Conf::Yaml;
use Ops::Main;

# Booleans
has 'all'        =>  ( isa => 'Bool', is => 'rw', default => 1 );  

# Int
has 'log'        =>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'printlog'   =>  ( isa => 'Int', is => 'rw', default => 1 );

# Strings
has 'branch'     => ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'configfile' => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'dumpfile'   => ( isa => 'Str|Undef', is => 'rw' );
has 'force'      => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'keyfile'    => ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'    => ( isa => 'Str|Undef', is => 'rw' );
has 'login'      => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'methods'    => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'appsdir'    => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'installdir' => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'opsdir'     => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'opsfile'    => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'owner'      => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'packagename'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'   => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'pmfile'     => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'privacy'    => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'repository' => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 's3bucket'   => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'status'     => ( isa => 'Str|Undef', is => 'rw' );
has 'token'      => ( isa => 'Str|Undef', is => 'rw' );
has 'treeish'    => ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'url'        => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'   => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'version'    => ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'versionfile'=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'conf'       => (
  is =>  'rw',
  isa => 'Conf::Yaml'
);

has 'db'      => ( 
  isa => 'Any', 
  is => 'rw', 
  required => 0 
);

has 'table'    =>  (
  is       =>  'rw',
  isa     =>  'Table::Main',
  # lazy    =>  1,
  # builder  =>  "setTable"
);

method setTable {
  my $table = Table::Main->new({
    dbfile  =>   $self->conf()->getKey("repo:INSTALLDIR") . "/" . $self->conf()->getKey("database:DBFILE"),
    conf      =>  $self->conf(),
    log        =>  $self->log(),
    printlog  =>  $self->printlog()
  });

  $self->table($table);  

}
has 'ops'   => (
  is     =>  'rw',
  isa   =>  'Ops::Main',
);

method BUILD ($hash) {
  # $self->logDebug("hash", $hash);
  my $args = $hash->{args};
  $self->getOpts( $args );
  # foreach my $key ( keys %$args ) {
  #   $self->logDebug("$key: $args->{$key}");
  #   $self->$key($args->{$key}) if $self->can($key);
  # }

  #### SET DATABASE
  $self->setTable();
}

method getOpts ( $args ) {
  foreach my $key ( keys %$args ) {
    my $value = $args->{ $key };
    $self->logDebug("key: $key");
    $key =~ s/^-+//g;
    $self->logDebug("FINAL key: $key");

    $self->logDebug( "value", $value );
    $self->$key( $value ) if $self->can($key);
  }
}

#### INSTALL
method install () {  
  my $packagename  =  $self->packagename();
  my $version      =  $self->version();
  my $versionfile  =  $self->versionfile();
  $self->logDebug( "packagename", $packagename );
  $self->logDebug( "version", $version );
  $self->logDebug( "versionfile", $versionfile );

  #### INSTALL USING packagename IF NO VERSIONFILE
  if ( $versionfile eq "" ) {
    return $self->_install( $packagename, $version ) ;
  }
  
  #### OTHERWISE, INSTALL FROM VERSIONFILE
  my $packages = $self->getVersionfilePackages( $versionfile );

  foreach my $package ( @$packages ) {

    my $packagename = $package->{packagename};
    my $version     = $package->{version};
    $self->logDebug("Installing package '$packagename' (version $version)");
    
    $self->_install( $packagename, $version );
  }
}

method getVersionfilePackages ( $versionfile ) {
  $self->logDebug( "versionfile", $versionfile );
  my $packages = [];
  my $lines  =  $self->getLines( $versionfile );
  foreach my $line ( @$lines ) {
    next if $line  =~  /^\s*$/;
    next if $line  =~  /^#/;
    my ($packagename, $version)  =  $line  =~ /^(\S+)\s+(\S+)/;
    print "Package not defined at line: $line\n" and exit if not defined $packagename;
    print "Version not defined at line: $line\n" and exit if not defined $version;

    push @$packages, { 
      packagename => $packagename,
      version     => $version
    };
  }

  return $packages;
}

method _install ( $packagename, $version ) {
  $self->logDebug( "packagename", $packagename );
  $self->logDebug( "version", $version );

  #### CHECK PACKAGE DEFINED
  if ( not defined $packagename ) {
    print "Package name not defined. Exiting\n";
    return ;
  }

  #### CHECK IF PACKAGE ALREADY INSTALLED
  my $force = $self->force();
  $self->logDebug( "force", $force );
  if ( $self->packageIsInstalled( $packagename, $version ) 
      and $version ne "latest" 
      and not $force ) {
    print "Package $packagename (version $version) already installed. Use '--force' option to override.\n";
    return;
  }
  
  #### SET STATUS
  my $status = $self->status() || "ok";

  #### GET USERNAME
  my $username    =   $self->getUsername();

  #### GET DIRS  
  my $appsdir     =   $self->appsdir() || $self->conf()->getKey("repo:APPSDIR");
  my $installdir  =   $self->installdir() || $self->conf()->getKey("repo:INSTALLDIR");
  my $opsdir      =   $self->opsdir() || $self->conf()->getKey("repo:OPSDIR");
  $self->logDebug("installdir", $installdir);
  $self->logDebug( "self->opsdir()", $self->opsdir() );
  $self->logDebug( "opsdir", $opsdir );  
    
  #### GET OPSFILE AND PMFILE
  my $opsfile     =  $self->opsfile();
  my $pmfile      =  $self->pmfile();
  $self->logDebug("opsfile", $opsfile);
  $self->logDebug("pmfile", $pmfile);

  #### SET VARIABLES FROM OPS INFO
  my $repository   =  $self->repository();
  my $login      =  $self->login();
  my $owner      =  $self->owner();
  my $privacy    =  $self->privacy();
  my $url      =  $self->url();
  my $branch     =  $self->branch();
  my $treeish    =  $self->treeish();
  $self->logDebug("repository", $repository);
  $self->logDebug("login", $login);
  $self->logDebug("owner", $owner);
  $self->logDebug("privacy", $privacy);
  $self->logDebug("url", $url);
  $self->logDebug("branch", $branch);
  $self->logDebug("treeish", $treeish);

  my $ops  =  $self->setOps( $owner, $login, $username, $repository, $packagename, $privacy, $installdir, $pmfile, $opsfile, $opsdir, $version, $branch, $treeish, $url, $status );

  $ops->install();
}

method packageIsInstalled ( $packagename, $version ) {
  my $query      =  qq{SELECT 1 FROM package
WHERE packagename='$packagename'
AND version='$version'};
  $self->logDebug("query", $query);
  my $found    =  $self->table()->db()->query($query);
  if ( not $found ) {
    return 0;
  }
  
  return 1;
}

method getUsername () {
  #### USE SUPPLIED USERNAME IF USER IS root
  my $username    =   $ENV{LOGNAME} || $ENV{USERNAME} || $ENV{USER}; 

  #### NO $USER ENVAR INSIDE docker CONTAINER
  if ( not defined $username ) {
    $username = $ENV{HOME};
    $username =~ s/^\/(home)?//;
  }

  if ( $username eq "root"  and $self->username() and $self->username() ne "" ) {
    $username = $self->username();
    $self->username( $username );
  }
  $self->logDebug("username", $username);

  return $username;  
}

method setOps ( $owner, $login, $username, $repository, $packagename, $privacy, $installdir, $pmfile, $opsfile, $opsdir, $version, $branch, $treeish, $url, $status ) {
  $self->logDebug("owner", $owner);
  $self->logDebug("login", $login);
  $self->logDebug("repository", $repository);
  $self->logDebug("packagename", $packagename);
  $self->logDebug("privacy", $privacy);
  $self->logDebug("branch", $branch);
  $self->logDebug("treeish", $treeish);

  $installdir = "$installdir/$packagename";
  $self->logDebug("installdir", $installdir);

  my $args  =  {
    owner       =>  $owner,
    login       =>  $login,
    repository  =>  $repository,
    username    =>  $username,
    packagename =>  $packagename,
    status      =>  $status,
    url         =>  $url,
    version     =>  $version,
    branch      =>  $branch,
    treeish     =>  $treeish,
    pmfile      =>  $pmfile,
    opsfile     =>  $opsfile,
    opsdir      =>  $opsdir,
    token       =>  $self->token(),
    keyfile     =>  $self->keyfile(),
    password    =>  $self->password(),
    privacy     =>  $privacy,
    installdir  =>  $installdir,
    logfile     =>  $self->logfile(),
    log         =>  $self->log(),
    printlog    =>  $self->printlog(),
    conf        =>  $self->conf(),
    table       =>  $self->table()
  };
  # $self->logDebug("args", $args);
  
  my $ops  =  Ops::Main->new($args);

  return $ops;
}

#### UNINSTALL SPECIFIC VERSION OF PACKAGE AND DELETE FROM DATABASE
method remove () {
  my $packagename  =  $self->packagename();
  my $version      =  $self->version();
  $self->logDebug("packagename", $packagename);
  $self->logDebug("version", $version);

  my $versionfile = $self->versionfile();
  #### REMOVE FROM VERSIONFILE IF DEFINED
  if ( $versionfile ) {
    my $packages = $self->getVersionfilePackages( $versionfile );

    foreach my $package ( @$packages ) {

      my $packagename = $package->{packagename};
      my $version     = $package->{version};
      $self->logDebug("Removing package '$packagename' (version $version)");
      
      $self->removePackage( $packagename, $version );
    }
  }
  #### OTHERWISE, REMOVE A SINGLE PACKAGE
  else {
    $self->removePackage( $packagename, $version );
  }
}

method removePackage ( $packagename, $version ) {
  $self->logDebug("packagename", $packagename);
  $self->logDebug("version", $version);

  print "Package not defined\n" and exit if not defined $packagename;
  print "Version not defined\n" and exit if not defined $version;
  print "Cannot remove repo\n" and exit if $packagename eq "repo";

  if ( not $self->packageIsInstalled( $packagename, $version ) ) {
    print "Can't find package in database: $packagename (version $version). Deleting installation directory if present.\n";
  } 
  
  my $appsdir = $self->conf()->getKey( "repo:APPSDIR" );
  my $versiondir = "$appsdir/$packagename/$version";
  $self->logDebug( "versiondir", $versiondir );
  if ( not -d $versiondir ) {
    print "Installation directory not found: $versiondir\n";
  }
  if ( -f $versiondir ) {
    print "Installation directory is actually a file: $versiondir\n";
  }

  #### DELETE INSTALLATION DIRECTORY
  rmtree( $versiondir );
  if ( -d $versiondir ) {
    print "Can't remove installation directory: $versiondir\n";
    exit;
  }

  #### REMOVE FROM DATABASE
  my $query      =  qq{DELETE FROM package
WHERE packagename='$packagename'
AND version='$version'};
  $self->logDebug("query", $query);
  my $success =  $self->table()->db()->do($query);
  if ( not $success ) {
    print "An error occurred trying to delete package from database: $packagename, version $version\n";
    exit;
  }

  print "Removed package: $packagename (version $version)\n";
}


#### VERSIONS
method versions () {
  my $packagename  =  $self->packagename();
  my $url          =  $self->url();
  my $installdir  =   $self->conf()->getKey("repo:INSTALLDIR");

  #### SET PACKAGE DETAILS
  $self->logDebug("packagename", $packagename);
  print "versions    Repo::install  packagename not defined. Exiting\n" and return if not defined $packagename;
  
  #### SET OPSDIR
  my $opsdir = "$installdir/package";
  $self->logDebug("opsdir", $opsdir);  

  my $args  =  {
    packagename =>  $packagename,
    url         =>  $url,
    opsdir      =>  $opsdir,

    log         =>  $self->log(),
    logfile     =>  $self->logfile(),
    printlog    =>  $self->printlog(),
    conf        =>  $self->conf(),
    table       =>  $self->table()
  };
  #$self->logDebug("args", $args);
  
  my $ops  =  Ops::Main->new( $args );
  $self->logDebug( "ops", $ops );

  my ( $versions, $source ) = $ops->getVersions();
  $self->logDebug( "versions", $versions );

  print "---- $packagename versions (source: $source) ----\n";
  foreach my $version ( @$versions ) {
    print "$version\n";
  }

  return;
}


#### SHOW DETAILS OF INSTALLED PACKAGE
method desc () {
  my $packagename  =  $self->packagename();
  my $version      =  $self->version();
  $self->logDebug( "packagename", $packagename );
  $self->logDebug( "version", $version );

  if ( $version ) {
    my $query = "SELECT * FROM package
WHERE packagename='$packagename'
AND version='$version'";
    $self->logDebug("query", $query);
    my $package    =  $self->table()->db()->queryhash($query);
    if ( not defined $package ) {
      print "\n\nCan't find package in database: $packagename (version $version)\n\n";
      exit;
    }
    else {
      my $output = $self->descPackage( $package );
      print $output;
      exit;
    }
  }
  else {
    my $query = "SELECT * FROM package
WHERE packagename='$packagename'";
    $self->logDebug("query", $query);
    my $packages    =  $self->table()->db()->queryhasharray($query);

    if ( not defined $packages ) {
      print "\n\nCan't find package in database: $packagename\n\n";
      exit;
    }
    else {
      foreach my $package ( @$packages ) {
        my $output = $self->descPackage( $package );
        print $output;
      }
    }
  }
  print "\n";
}

method descPackage ( $package ) {
  my $fields = $self->table()->db()->fields( "package" );
  @$fields = sort @$fields;
  my $output = "";
  my $maxwidth = $self->getMaxWidth( $fields );
  my $gap = 2;

  my $packagename = $package->{packagename};
  my $version = $package->{version};
  print "\n---- $packagename ($version ) ----\n";

  foreach my $field ( @$fields ) {
    next if not $package->{$field};
    next if $field eq "packagename";

    my $length = length( $field );
    my $space = $maxwidth - $length;
    my $value = $package->{$field};
    $value =~ s/\s*$//g;
    $output .= $field;
    $output .= " " x $space;
    $output .= " " x $gap;
    $output .= ":    ";
    $output .= $value;
    $output .= "\n"; 
  }

  return $output;
}

method getMaxWidth ( $array ) {
  my $maxwidth = 0;
  foreach my $entry ( @$array ) {
    if ( length( $entry ) > $maxwidth ) {
      $maxwidth = length( $entry );
    }
  }

  return $maxwidth;
}

#### LIST INSTALLED PACKAGES WITH VERSIONS
method list {
  my $all = $self->all();
  $self->logDebug( "all", $all );
  my $username = $self->getUsername();

  my $query      =  qq{SELECT packagename, version, status, installed FROM package};
  $self->logDebug("query", $query);
  my $packages    =  $self->table()->db()->queryhasharray($query);
  if ( not defined $packages ) {
    print "\n\nNo packages currently installed\n\n";
  }
  else {
    my $headers = [ "package", "version", "installed", "status" ];
    my $widths = $self->getColumnWidths( $headers, $packages );
    my $space = "    ";

    my $output = "\nList of installed packages:\n\n";
    $output .= $self->formatColumn( $widths, [ "package", "version", "installed", "status" ] );
    $output .= "\n";

    foreach my $package ( @$packages ) {
      $self->logDebug("package", $package);
      my $installed = $package->{installed} || "";
      my $status = $package->{status} || "";
      $output .= $self->formatColumn( $widths, [ $package->{packagename}, $package->{version}, $package->{installed}, $package->{status} ] );
      $output .= "\n";
    }
    print "$output\n";
  }
}

method formatColumn( $widths, $array ) {
  my $output = "";
  my $gap = 2;
  for ( my $i = 0; $i < scalar( @$array ); $i++ ) {
    my $field = $$array[ $i ];
    my $length = length( $field );
    my $space = $$widths[ $i ] - $length;
    $output .= $field;
    $output .= " " x $space;
    $output .= " " x $gap;
  }

  # $output =~ s/\s+//g;
  $self->logDebug( "output", $output );

  return $output;
}

method getColumnWidths( $headers, $packages ) {
  my $widths = [ 0, 0, 0, 0 ];
  my $headerfields = [ "package", "version", "installed", "status" ];
  for ( my $i = 0; $i < scalar( @$headerfields ); $i++ ) {
    if ( length( $$headerfields[ $i ] ) > $$widths[ $i ] ) {
      $$widths[ $i ] = length( $$headerfields[ $i ] );
    }
  }
  $self->logDebug( "widths", $widths );

  my $fields = [ "packagename", "version", "installed", "status" ];
  foreach my $package ( @$packages ) {
    for ( my $i = 0; $i < scalar( @$fields ); $i++ ) {
      my $field = $$fields[ $i ];
      my $value = $package->{ $field };
      my $length = length ( $value );
      $self->logDebug( "$field value", $value );
      $self->logDebug( "length", $length );
      if ( $length > $$widths[ $i ] ) {
        $$widths[ $i ] = $length;
      }
    }
   }
  $self->logDebug( "FINAL widths", $widths );

  return $widths;
}

#### LIST AVAILABLE PACKAGEINSTALLERS
method available {
  my $installdir = $self->conf()->getKey("repo:INSTALLDIR");
  $self->logDebug("installdir", $installdir);
  my $directory = "$installdir/package";
  $self->logDebug("directory", $directory);
  my $dirs = $self->getDirs($directory);
  @$dirs = sort {  "\L$a" cmp "\L$b" } @$dirs;
  $self->logDebug("dirs", $dirs);

  my $padding = 4;
  my $length = 0;
  foreach my $dir ( @$dirs ) {
    $length = length $dir if length $dir > $length;
  }

  my $packages    =  [];
  my $conf = Conf::Yaml->new({
    log => $self->log()  
  });
  foreach my $dir ( @$dirs ) {
    #### SKIP IF INSTALLER IN DEVELOPMENT
    next if $dir =~ /^_/;

    my $opsfile = "$directory/$dir/$dir.ops";
    $self->logDebug("opsfile", $opsfile);
    if ( -f $opsfile ) {
      $self->logDebug("Reading opsfile");

      $conf->inputfile( $opsfile );
      my $description = $conf->getKey("description") || "";
      $self->logDebug("description", $description);
      my $package = {
        packagename  => $dir,
        description  => $description
      };

      push( @$packages, $package );
    }
    else {
      $self->logDebug( "FILE NOT FOUND: $opsfile" );
    }
  }

  print "\n---- List of available packages ----\n";
  foreach my $package ( @$packages ) {
    my $dir = $package->{packagename};
    my $output = $dir;
    my $gap = $length  - ( length $dir )  + $padding;
    $output .= " "  x $gap;
    $output .= $package->{description} || "";
    $output .= "\n";
    print $output;
  }
}

method getDirs ($directory) {
    $self->logDebug("directory", $directory);
    
    opendir(DIR, $directory) or $self->logError("Can't open directory: $directory") and exit;
    my $dirs;
    @$dirs = readdir(DIR);
    closedir(DIR) or die "Can't close directory: $directory";
    $self->logNote("RAW dirs", $dirs);
    
    for ( my $i = 0; $i < @$dirs; $i++ ) {
        if ( $$dirs[$i] =~ /^\.+$/ ) {
            splice @$dirs, $i, 1;
            $i--;
        }
    }
    
    for ( my $i = 0; $i < @$dirs; $i++ ) {
        last if scalar(@$dirs) == 0 or $dirs == [];
        my $filepath = "$directory/$$dirs[$i]";
        if ( not -d $filepath ) {
            splice @$dirs, $i, 1;
            $i--;
        }
    }
    $self->logNote("FINAL dirs", $dirs);
    
    return $dirs;    
}

#### CREATE SKELETON *.ops AND *.pm FILES FOR NEW PACKAGE
method skel {
  my $packagename    =  $self->packagename();
  my $version        =  $self->version();
  my $methods        =  $self->methods();
  $self->logDebug("packagename", $packagename);
  $self->logDebug("methods", $methods);
  
  print "Methods not defined\n" and return if not defined $methods;
  $self->logDebug("methods", $methods);
  
  #### SET TARGET DIR  
  my $targetdir  =  $self->getSkelTargetDir($packagename);
  $self->logDebug("targetdir", $targetdir);
  
  #### QUIT IF TARGET DIR EXISTS
  print "\n\nExited because targetdir already exists: $targetdir\n\n" and return 0 if -d $targetdir;

  #### PRINT PM FILE
  my $pm  =  $self->getSkelPm($packagename, $methods);
  $self->logDebug("pm", $pm);
  my $pmfile  =  "$targetdir/$packagename.pm";
  $self->printToFile($pmfile, $pm);
  
  #### PRINT OPS FILE
  my $ops  =  $self->getSkelOps($packagename, $version);
  $self->logDebug("ops", $ops);
  my $opsfile  =  "$targetdir/$packagename.ops";
  $self->printToFile($opsfile, $ops);  
}

method getSkelOps ($packagename, $version) {
  my $username = $self->getUsername();

  my $ops      =  qq{---
  description  :  
  hubtype      :  bitbucket,
  owner        :  $username,
  packagename  :  $packagename,
  repository   :  $packagename,
  version      :  [ 0.0.1 ],
  privacy      :  private,
  keywords     :  [],
  url          :  ,
  installtype  :  git,
  licensefile  :  LICENSE,
  readmefile   :  README,
  authors      :  [],
  website      :  ,
  publication  :  {},
  resources    :  {}
};

  return $ops;  
}

method getLines ($file) {
  $self->logDebug("file", $file);
  $self->logWarning("file not defined") and return if not defined $file;
  my $temp = $/;
  $/ = "\n";
  open(FILE, $file) or $self->logCritical("Can't open file: $file\n") and exit;
  my $lines;
  @$lines = <FILE>;
  close(FILE) or $self->logCritical("Can't close file: $file\n") and exit;
  $/ = $temp;
  
  for ( my $i = 0; $i < @$lines; $i++ ) {
    if ( $$lines[$i] =~ /^\s*$/ ) {
      splice @$lines, $i, 1;
      $i--;
    }
  }
  
  return $lines;
}

method getSkelTargetDir ($packagename) {
  my $basedir     =   $self->conf()->getKey("repo:INSTALLDIR");
  my $targetdir  =  "$basedir/$packagename";

  return $targetdir;  
}

method getSkelPm ($packagename, $methods) {
  my $template  =  $self->getSkelTemplate();
  $self->logDebug("template", $template);
  my $contents  =  $self->getFileContents($template);
  $self->logDebug("contents", $contents);

  my $subs    =  $self->getSkelSubs($methods);

  $contents    =~  s/<PACKAGE>/$packagename/g;
  my $subroutines  =  "";
  foreach my $sub ( @$subs ) {
    $subroutines  .=  "  return 0 if not \$self->$sub(\$installdir, \$version);\n";
  }
  $self->logDebug("subroutines", $subroutines);
  
  $contents    =~  s/<SUBROUTINES>/$subroutines/;
  $self->logDebug("contents", $contents);
  
  return $contents;  
}

method getSkelTemplate {
  my $installdir  =   $self->conf()->getKey("repo:INSTALLDIR");
  my $opsdir = "$installdir/package";  
  my $template  =  "$opsdir/templates/skel.pm";
  $self->logDebug("template", $template);  

  return $template;
}

method getSkelSubs ($methods) {
  $self->logDebug("methods", $methods);
  
  my @array  =  split ",", $methods;
  my $subs;
  foreach my $entry ( @array ) {
    push @$subs, $entry . "Install";
  }
  $self->logDebug("subs", $subs);

  return $subs;  
}



}

