What is ADVTrustStore
=====================

ADVTrustStore is a simple management script to import/list/remove CA certificates 
to the iOS simulator.

Importing CA certificates is not directly supported in the iOS simulator.

Custom CA certificates are stored in a file named TrustStore.sqlite3 in both the
physical device and the iOS simulator.  Some scripts are available to import 
a CA certificate to the iOS simulator but they work only for version lower than 5.0.

Without this tool, the common method to add CA certificates to the iOS simulator 5.0 and 
above was to import it on a physical device, then extract the TrustStore.sqlite3 file 
from a device backup then copy the relevant records to the to the version in iOS simulator.

ADVTrustStore works with all versions from 5.0 to the current 6.1 version. In addition to
directly import of a CA certificate from a PEM encoded certificate file, it provides
the following functions:

- list custom CA certificates in each of the iOS simulator versions

- selectively remove custom CA certificates to each of the iOS simulator versions

- selectively export custom CA certificates from each of the iOS simulator versions

- selectively export custom CA certificates from device backup

How to use ADVTrustStore
========================


Just copy the iosCertTrustManager.py to a Mac OS X system. This python script does not
requires any additional python module.

Help on the command line arguments is available with:

iosCertTrustManager.py --help

To import a certificate form a PEM file:

iosCertTrustManager.py -a certificate_file

For each available iOS simulator version it will prompt to install the CA certificate.


ADVTrustStore files
===================

iosCertTrustManager.py: the TrustStore manager script

IOSTrustStore Structure.pdf: A documentation with the known details of the 
TrustStore.sqlite3 database format


Copyright and license
=====================

Written by Daniel Cerutti

Copyright (c) 2013 - [ADVTOOLS SARL](http://www.advtools.com)
 
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.