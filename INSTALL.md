INSTALL


1. Dependencies

# CPAN MINUS
Ubuntu:
apt-get -y install cpanminus
apt-get -y install perl-doc
apt-get -y install unzip
apt-get -y install wget

Centos:
yum install -y perl-Pod-Perldoc.noarch
yum install -y cpanminus
yum -y install unzip
yum -y install wget


# PERL MODS
cpanm install JSON
cpanm install Term::ReadKey


2. Installation

Run the applications in the following order:

cd bin/install
./install.pl
./configure.pl
./deploy.pl --mode repo


For details on custom options for these scripts, see the following sections.

2.1 install.pl   Installs dependencies and sets up the directory hierarchy

USAGE

sudo ./install.pl \
 [--mode String] \
 [--installdir String] \
 [--apachedir String] \
 [--userdir String] \
 [--wwwdir String] \
 [--wwwuser String] \
 [--domainname String] \
 [--logfile String] \
 [--newlog] \
 [--help]

 --mode          :  Installation option (see ./install.pl -h for options)
 --target        :  Target directory to install repository to (e.g., 1.2.0)
 --urlprefix     :  Prefix to URL (e.g., http://myhost.com/URLPREFIX/agua.html)
                    (default: agua)
 --userdir       :  Path to users home directory (default: /nethome)
 --wwwdir        :  Path to 'WWW' directory (default: /var/www)
 --wwwuser       :  Name of apache user (default: "www-data")
 --apachedir     :  Path to apache installation (default: /etc/apache2)
 --domainname    :  Domain name to use for CA certificate
 --logfile       :  Print log to this file
 --newlog        :  Flag to create new log file and backup old
 --help          :  Print help info
 
EXAMPLE

sudo install.pl --installdir /path/to/installdir


2.2 configure.pl  Configures items including the database and load balancer monitor
                    and creates the 'admin' user.

USAGE

sudo ./configure.pl \
    [--mode String] 

    --mode config   Default 'config' mode: do all the following config tasks
    --mode mysql    Install Agua mysql database and DB user
    --mode cron     Create cron job to monitor StarCluster load balancer
    --mode user     Create 'admin' user

EXAMPLE

sudo ./configure.pl --mode mysql


2.3 deploy.pl    Deploys Agua dependencies (e.g., StarCluster, BioApps)

USAGE:

sudo ./deploy.pl \
 [--mode String] \ 
 [--configfile String] \ 
 [--logfile String] \ 
 [--help]

 --mode      :    deploy | bioapps | repo | ... options (see below)
 --configfile:    Location of configfile
 --logfile   :    Location of logfile
 --help      :    Print help info

The 'mode' options are as follows:

	--mode aguatest    Install the Agua tests package
	--mode bioapps     Install the Bioapps package
	--mode repo     Install the Biorepository package
	--mode sge         Install the SGE (Sun Grid Engine) package
	--mode starcluster Install the StarCluster package
	--mode deploy      (DEFAULT) Do all of the above

The script can also be used to install other packages, for example, analysis tools for workflows:

	--mode install --package packagename --version 0.0.4
                       Install version 0.0.4 of package 'packagename' 

Alternately, show the full list of installed packages and the latest versions of available packages:

    --mode list
    
Or, install all of the listed packages:

    --mode all


EXAMPLE
-------

sudo /agua/bin/install/deploy.pl --mode install --package samtools --version 0.1.19



