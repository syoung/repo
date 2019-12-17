README

# repo

## 0. SUMMARY

Biorepo is an open-source package installer that enables you to install Linux-supported software tools and workflows as a non-root user. Biorepo-installed workflows run using the Agua [https://github.com/agua/agua](https://github.com/agua/agua) open-source workflow platform either on a local machine, in a high performance computing (HPC) cluster and in the Cloud. Information about Agua is available at www.aguadev.org

## 1. INTRODUCTION

The Biopackage repository is used by package installer Biorepo [www.github.com/agua/repo](www.github.com/agua/repo) to automatically install packages and workflows. Biopackage is a collection of application-specific installation scripts that Biorepo uses to carry out installations and test the correct functioning of the installed packages. Installed executables can be run on the Linux command line or using the open-source workflow platform Agua (www.github.com/agua/agua).

If you don't find the package you need in Biopackage, you can submit a feature request to: aguadev@gmail.com

1. Before You Install
2. Installation
3. Resources
4. Developers
5. License

# 1. Before You Install

## 1.1 Hardware requirements

Memory   512MB RAM
Storage  230 MB

Please note that you may need several GBs of storage to house the application files you install using the repo. (To determine how much disk space you have, use the 'df -ah' command.)

## 1.2 Operating system

Supported operating systems

Ubuntu 16.04
Centos 7.3

## 1.3 Software

Required software packages: 

Perl 5.10+
Git 1.6+

You can verify these versions with the following commands:

perl --version
git --version

To install these packages on Ubuntu/Debian:

sudo apt-get install -y git
sudo apt-get install -y cpanminus

To install the dependencies on Centos/Fedora/Redhat:

sudo yum install perl-devel
sudo yum install perl-CPAN
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
sudo yum install git


2. Installation
===============

Install the dependencies as describeda above then follow the instructions below to download the source code from Github and install the package.2.1 Dependencies

# 2.2 Download and Install

Run the following commands to install Biorepo:

```bash
git clone https://github.com/agua/repo --recursive
cd repo
./extlib.sh
```

This will download Biorepo and its submodules, copy from templates the config.yml and db.sqlite files if they don't already exist, and add the installation directory to the config.yml file. Installed submodules include the Biopackage repo, which contains installation modules for popular Bioinformatics applications.

3. Resources
============

See (http://www.aguadev.org)[http://www.aguadev.org] for information on Biorepo, Biopackage, Agua and other related resources.


4. Developers
=============

If you'd like to tweak, fix, customize or otherwise improve Biorepo or add packages to Biopackage, see this file for details:

packages/README.md 

5. License
==========

MIT Licence (see LICENSE.txt file for details).
