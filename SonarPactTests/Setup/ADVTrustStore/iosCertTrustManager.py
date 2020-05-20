#! /usr/bin/env python

# Script to manage additional trusted root certificate in the IOS simulator
#
# Allows to add/list/delete/export trusted root certificates to the IOS simulator
# TrustStore.sqlite3 file.
#
# Additionally, root certificates added to a device can be listed and exported from 
# a device backup
#
# type ./iosCertTrustManager.py -h for help
#
#
# This script contains code derived from Python-ASN1 to parse and re-encode
# ASN1. The following notice is included:
#
# Python-ASN1 is free software that is made available under the MIT license. 
# Consult the file "LICENSE" that is
# distributed together with this file for the exact licensing terms.
#
# Python-ASN1 is copyright (c) 2007-2008 by Geert Jansen <geert@boskant.nl>. 
# see https://github.com/geertj/python-asn1

import os
import sys
import argparse
import sqlite3
import ssl
import hashlib
import subprocess
import string
import binascii
import plistlib

def query_yes_no(question, default="yes"):
    """Ask a yes/no question via raw_input() and return their answer.
    
    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).

    The "answer" return value is one of "yes" or "no".
    """
    valid = {"yes":"yes",   "y":"yes",  "ye":"yes",
             "no":"no",     "n":"no"}
    if default == None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while 1:
        sys.stdout.write(question + prompt)
        choice = raw_input().lower()
        if default is not None and choice == '':
            return default
        elif choice in valid.keys():
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' "\
                             "(or 'y' or 'n').\n")

#----------------------------------------------------------------------
# A simple ASN1 decoder/encoder based on Python-ASN1
#----------------------------------------------------------------------

class ASN1:
    Sequence = 0x10
    Set = 0x11
    PrintableString = 0x13

    TypeConstructed = 0x20
    TypePrimitive = 0x00

    ClassUniversal = 0x00
    ClassApplication = 0x40
    ClassContext = 0x80
    ClassPrivate = 0xc0

class Error(Exception):
    """ASN1 error"""


class Encoder(object):
    """A simple ASN.1 encoder. Uses DER encoding."""

    def __init__(self):
        """Constructor."""
        self.m_stack = None

    def start(self):
        """Start encoding."""
        self.m_stack = [[]]

    def enter(self, nr, cls):
        """Start a constructed data value."""
        if self.m_stack is None:
            raise Error, 'Encoder not initialized. Call start() first.'
        self._emit_tag(nr, ASN1.TypeConstructed, cls)
        self.m_stack.append([])

    def leave(self):
        """Finish a constructed data value."""
        if self.m_stack is None:
            raise Error, 'Encoder not initialized. Call start() first.'
        if len(self.m_stack) == 1:
            raise Error, 'Tag stack is empty.'
        value = ''.join(self.m_stack[-1])
        del self.m_stack[-1]
        self._emit_length(len(value))
        self._emit(value)

    def write(self, value, nr, typ, cls):
        """Write a primitive data value."""
        if self.m_stack is None:
            raise Error, 'Encoder not initialized. Call start() first.'
        self._emit_tag(nr, typ, cls)
        self._emit_length(len(value))
        self._emit(value)

    def output(self):
        """Return the encoded output."""
        if self.m_stack is None:
            raise Error, 'Encoder not initialized. Call start() first.'
        if len(self.m_stack) != 1:
            raise Error, 'Stack is not empty.'
        output = ''.join(self.m_stack[0])
        return output

    def _emit_tag(self, nr, typ, cls):
        """Emit a tag."""
        if nr < 31:
            self._emit_tag_short(nr, typ, cls)
        else:
            self._emit_tag_long(nr, typ, cls)

    def _emit_tag_short(self, nr, typ, cls):
        """Emit a short (< 31 bytes) tag."""
        assert nr < 31
        self._emit(chr(nr | typ | cls))

    def _emit_tag_long(self, nr, typ, cls):
        """Emit a long (>= 31 bytes) tag."""
        head = chr(typ | cls | 0x1f)
        self._emit(head)
        values = []
        values.append((nr & 0x7f))
        nr >>= 7
        while nr:
            values.append((nr & 0x7f) | 0x80)
            nr >>= 7
        values.reverse()
        values = map(chr, values)
        for val in values:
            self._emit(val)

    def _emit_length(self, length):
        """Emit length octects."""
        if length < 128:
            self._emit_length_short(length)
        else:
            self._emit_length_long(length)

    def _emit_length_short(self, length):
        """Emit the short length form (< 128 octets)."""
        assert length < 128
        self._emit(chr(length))

    def _emit_length_long(self, length):
        """Emit the long length form (>= 128 octets)."""
        values = []
        while length:
            values.append(length & 0xff)
            length >>= 8
        values.reverse()
        values = map(chr, values)
        # really for correctness as this should not happen anytime soon
        assert len(values) < 127
        head = chr(0x80 | len(values))
        self._emit(head)
        for val in values:
            self._emit(val)

    def _emit(self, s):
        """Emit raw bytes."""
        assert isinstance(s, str)
        self.m_stack[-1].append(s)


class Decoder(object):
    """A minimal ASN.1 decoder. Understands BER (and DER which is a subset)."""

    def __init__(self):
        """Constructor."""
        self.m_stack = None
        self.m_tag = None

    def start(self, data):
        """Start processing `data'."""
        if not isinstance(data, str):
            raise Error, 'Expecting string instance.'
        self.m_stack = [[0, data]]
        self.m_tag = None

    def peek(self):
        """Return the value of the next tag without moving to the next
        TLV record."""
        if self.m_stack is None:
            raise Error, 'No input selected. Call start() first.'
        if self._end_of_input():
            return None
        if self.m_tag is None:
            self.m_tag = self._read_tag()
        return self.m_tag

    def read(self):
        """Read a simple value and move to the next TLV record."""
        if self.m_stack is None:
            raise Error, 'No input selected. Call start() first.'
        if self._end_of_input():
            return None
        tag = self.peek()
        length = self._read_length()
        value = self._read_value(tag[0], length)
        self.m_tag = None
        return (tag, value)

    def eof(self):
        """Return True if we are end of input."""
        return self._end_of_input()

    def enter(self):
        """Enter a constructed tag."""
        if self.m_stack is None:
            raise Error, 'No input selected. Call start() first.'
        nr, typ, cls = self.peek()
        if typ != ASN1.TypeConstructed:
            raise Error, 'Cannot enter a non-constructed tag.'
        length = self._read_length()
        bytes = self._read_bytes(length)
        self.m_stack.append([0, bytes])
        self.m_tag = None

    def leave(self):
        """Leave the last entered constructed tag."""
        if self.m_stack is None:
            raise Error, 'No input selected. Call start() first.'
        if len(self.m_stack) == 1:
            raise Error, 'Tag stack is empty.'
        del self.m_stack[-1]
        self.m_tag = None

    def _read_tag(self):
        """Read a tag from the input."""
        byte = self._read_byte()
        cls = byte & 0xc0
        typ = byte & 0x20
        nr = byte & 0x1f
        if nr == 0x1f:
            nr = 0
            while True:
                byte = self._read_byte()
                nr = (nr << 7) | (byte & 0x7f)
                if not byte & 0x80:
                    break
        return (nr, typ, cls)

    def _read_length(self):
        """Read a length from the input."""
        byte = self._read_byte()
        if byte & 0x80:
            count = byte & 0x7f
            if count == 0x7f:
                raise Error, 'ASN1 syntax error'
            bytes = self._read_bytes(count)
            bytes = [ ord(b) for b in bytes ]
            length = 0L
            for byte in bytes:
                length = (length << 8) | byte
            try:
                length = int(length)
            except OverflowError:
                pass
        else:
            length = byte
        return length

    def _read_value(self, nr, length):
        """Read a value from the input."""
        bytes = self._read_bytes(length)
        value = bytes
        return value

    def _read_byte(self):
        """Return the next input byte, or raise an error on end-of-input."""
        index, input = self.m_stack[-1]
        try:
            byte = ord(input[index])
        except IndexError:
            raise Error, 'Premature end of input.'
        self.m_stack[-1][0] += 1
        return byte

    def _read_bytes(self, count):
        """Return the next `count' bytes of input. Raise error on
        end-of-input."""
        index, input = self.m_stack[-1]
        bytes = input[index:index+count]
        if len(bytes) != count:
            raise Error, 'Premature end of input.'
        self.m_stack[-1][0] += count
        return bytes

    def _end_of_input(self):
        """Return True if we are at the end of input."""
        index, input = self.m_stack[-1]
        assert not index > len(input)
        return index == len(input)

#----------------------------------------------------------------------
# Certificate class
#----------------------------------------------------------------------

class Certificate:
    """Represents a loaded certificate
    """
    def __init__(self):
        self._init_data()

    def _init_data(self):
        self._fingerprint = None
        self._data = None
        self._subject = None
        self._filepath = None

    def load_PEMfile(self, certificate_path):
        """Load a certificate from a file in PEM format
        """
        self._init_data()
        self._filepath = certificate_path
        with open(self._filepath, "r") as inputFile:
            PEMdata = inputFile.read()
        # convert to binary (DER format)
        self._data = ssl.PEM_cert_to_DER_cert(PEMdata)

    def save_PEMfile(self, certificate_path):
        """Save a certificate to a file in PEM format
        """
        self._filepath = certificate_path
        # convert to text (PEM format)
        PEMdata = ssl.DER_cert_to_PEM_cert(self._data)
        with open(self._filepath, "w") as output_file:
            output_file.write(PEMdata)
        
    def load_data(self, data):
        self._init_data()
        self._data = data
        
    def get_data(self):
        return self._data

    def get_fingerprint(self):
        if self._fingerprint == None and self._data != None:
            sha1 = hashlib.sha1()
            sha1.update(self._data)
            self._fingerprint = sha1.digest()
        return self._fingerprint 

    def get_subject(self):
        """Get the certificate subject in human readable one line format
        """
        if self._data != None:
            # use openssl to extract the subject text in single line format
            possl = subprocess.Popen(['openssl',  'x509', '-inform',  'DER',  '-noout',  '-subject', '-nameopt', 'oneline'], 
                shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=None)
            subjectText, error_text = possl.communicate(self.get_data())
            return subjectText
        return None

    def get_subject_ASN1(self):
        """Get the certificate subject in ASN1 encoded format as expected for the IOS trusted certificate keychain store
        """
        if self._subject == None and self._data != None:
            self._subject = bytearray()
            decoder = Decoder()
            decoder.start(self._data)
            decoder.enter()
            decoder.enter()
            tag, value = decoder.read()  # read version
            tag, value = decoder.read()  # serial
            tag, value = decoder.read()  
            tag, value = decoder.read()  # issuer
            tag, value = decoder.read()  # date
            decoder.enter() # enter in subject
            encoder = Encoder()
            encoder.start()
            self._process_subject(decoder, encoder)
            self._subject = encoder.output()
        return self._subject

    def _process_subject(self, input, output, indent=0):
        # trace = sys.stdout
        while not input.eof():
            tag = input.peek()
            if tag[1] == ASN1.TypePrimitive:
                tag, value = input.read()
                if tag[0] == ASN1.PrintableString:
                    value = string.upper(value)
                output.write(value, tag[0], tag[1], tag[2])
                #trace.write(' ' * indent)
                #trace.write('[%s] %s (value %s)' %
                #         (strclass(tag[2]), strid(tag[0]), repr(value)))
                #trace.write('\n')
            elif tag[1] == ASN1.TypeConstructed:
                #trace.write(' ' * indent)
                #trace.write('[%s] %s:\n' % (strclass(tag[2]), strid(tag[0])))
                input.enter()
                output.enter(tag[0], tag[2])
                self._process_subject(input, output, indent+2)
                output.leave()
                input.leave()

#----------------------------------------------------------------------
# IOS TrustStore.sqlite3 handling
#----------------------------------------------------------------------

class TrustStore:
    """Represents the IOS trusted certificate store
    """
    def __init__(self, path, title=None):
        self._path = path
        if title: 
            self._title = title 
        else: 
            self._title = path
        self._tset = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"\
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"\
            "<plist version=\"1.0\">\n"\
            "<array/>\n"\
            "</plist>\n"
        #with open('cert_tset.plist', "rb") as inputFile:
        #    self._tset = inputFile.read()
    
    
    def is_valid(self):
        conn = sqlite3.connect(self._path)
        c = conn.cursor()
        row = c.execute('SELECT count(*) FROM sqlite_master WHERE type=\'table\' AND name=\'tsettings\'').fetchone()
        conn.close()
        return (row[0] > 0) 
    
    def _add_record(self, sha1, subj, tset, data):
        if not self.is_valid():
            print "  Invalid TrustStore.sqlite3"
            return
        conn = sqlite3.connect(self._path)
        c = conn.cursor()
        c.execute('SELECT COUNT(*) FROM tsettings WHERE subj=?', [sqlite3.Binary(subj)])
        row = c.fetchone()
        if row[0] == 0:
            c.execute('INSERT INTO tsettings (sha1, subj, tset, data) VALUES (?, ?, ?, ?)', [sqlite3.Binary(sha1), sqlite3.Binary(subj), sqlite3.Binary(tset), sqlite3.Binary(data)])
            print '  Certificate added'
        else:
            c.execute('UPDATE tsettings SET sha1=?, tset=?, data=? WHERE subj=?', [sqlite3.Binary(sha1), sqlite3.Binary(tset), sqlite3.Binary(data), sqlite3.Binary(subj)])
            print '  Existing certificate replaced'
        conn.commit()
        conn.close()

    def _loadBlob(self, baseName, name):
        with open(baseName + '_' + name + '.bin', 'rb') as inputFile:
            return inputFile.read()

    def _saveBlob(self, baseName, name, data):
        with open(baseName + '_' + name + '.bin', 'wb') as outputFile:
            outputFile.write (data)

    
    def add_certificate(self, certificate):
        self._add_record(certificate.get_fingerprint(), certificate.get_subject_ASN1(), 
            self._tset, certificate.get_data())
    
    def export_certificates(self, base_filename):
        if not self.is_valid():
            print "  Invalid TrustStore.sqlite3"
            return
        conn = sqlite3.connect(self._path)
        c = conn.cursor()
        index = 1
        print
        print self._title
        for row in c.execute('SELECT subj, data FROM tsettings'):
            cert = Certificate()
            cert.load_data(row[1])
            if query_yes_no("  " + cert.get_subject() + "    Export certificate", "no") == "yes":
                cert.save_PEMfile(base_filename + "_" + str(index) + ".crt")
                index = index + 1
        conn.close()
    
    def export_certificates_data(self, base_filename):
        if not self.is_valid():
            print "  Invalid TrustStore.sqlite3"
            return
        conn = sqlite3.connect(self._path)
        c = conn.cursor()
        index = 1
        for row in c.execute('SELECT sha1, subj, tset, data FROM tsettings'):
            cert = Certificate()
            cert.load_data(row[3])
            if query_yes_no("  " + cert.get_subject() + "    Export certificate", "no") == "yes":
                base_filename2 = base_filename + "_" + str(index)
                self._saveBlob(base_filename2, 'sha1', row[0])
                self._saveBlob(base_filename2, 'subj', row[1])
                self._saveBlob(base_filename2, 'tset', row[2])
                self._saveBlob(base_filename2, 'data', row[3])
        conn.close()

    def import_certificate_data(self, base_filename):
        certificateSha1 = self._loadBlob(base_filename, 'sha1')
        certificateSubject = self._loadBlob(base_filename, 'subj')
        certificateTSet = self._loadBlob(base_filename, 'tset')
        certificateData = self._loadBlob(base_filename, 'data')
        self._add_record(certificateSha1, certificateSubject, certificateTSet, certificateData)

    def list_certificates(self):
        print
        print self._title
        if not self.is_valid():
            print "  Invalid TrustStore.sqlite3"
            return
        conn = sqlite3.connect(self._path)
        c = conn.cursor()
        for row in c.execute('SELECT data FROM tsettings'):
            cert = Certificate()
            cert.load_data(row[0])
            print "  ", cert.get_subject()
        conn.close()

    def delete_certificates(self):
        if not self.is_valid():
            print "  Invalid TrustStore.sqlite3"
            return
        conn = sqlite3.connect(self._path)
        c = conn.cursor()
        print
        print self._title
        todelete = []
        for row in c.execute('SELECT subj, data FROM tsettings'):
            cert = Certificate()
            cert.load_data(row[1])
            if query_yes_no("  " + cert.get_subject() + "    Delete certificate", "no") == "yes":
                todelete.append(row[0])
        for item in todelete:
            c.execute('DELETE FROM tsettings WHERE subj=?', [item])
        conn.commit()
        conn.close()

#----------------------------------------------------------------------
# IOS Simulator access
#----------------------------------------------------------------------

class IOSSimulator:
    """Represents an instance of an IOS simulator folder
    """
    simulatorDir = os.getenv('HOME') + "/Library/Developer/CoreSimulator/Devices/"
    trustStorePath = "/data/Library/Keychains/TrustStore.sqlite3"
    runtimeName = "com.apple.CoreSimulator.SimRuntime.iOS-"
    
    def __init__(self, simulatordir):
        self._is_valid = False
        infofile = simulatordir + "/device.plist"
        if os.path.isfile(infofile):
            info = plistlib.readPlist(infofile)
            runtime = info["runtime"]
            if runtime.startswith(self.runtimeName):
                self.version = runtime[len(self.runtimeName):].replace("-", ".")
            else:
                self.version = runtime
            self.title = info["name"] + " v" + self.version
            self.truststore_file = simulatordir + self.trustStorePath
            if os.path.isfile(self.truststore_file):
                self._is_valid = True
            
        
    def is_valid(self):
        return self._is_valid

def ios_simulators():
    """An iterator over the available IOS simulator versions
    """
    for subdir in os.listdir(IOSSimulator.simulatorDir):
        simulatordir = IOSSimulator.simulatorDir + subdir
        if os.path.isdir(simulatordir):
            simulator = IOSSimulator(simulatordir)
            if simulator.is_valid():
                yield simulator
        
#----------------------------------------------------------------------
# Device backup support
#----------------------------------------------------------------------

class DeviceBackup:
    """Represents an instance of an IOS simulator folder
    """
    trustStore_filename = "61c8b15a0110ab17d1b7467c3a042eb1458426c6"
    
    def __init__(self, path):
        self._path = path
        self._isvalid = False
        info_plist = self._path + "/Info.plist"
        if os.path.isfile(info_plist):
            try:
                info = plistlib.readPlist(info_plist)
                self.device_name = info["Device Name"]
                self.title = "Backup of " + self.device_name + " - " + str(info["Last Backup Date"])
                self._isvalid = True
            except:
                pass
        
    def is_valid(self):
        return self._isvalid
    
    def get_truststore_file(self):
        return self._path + "/" + DeviceBackup.trustStore_filename


def device_backups():
    """An iterator over the available device backups
    """
    base_backupdir = os.getenv('HOME') + "/Library/Application Support/MobileSync/Backup/"
    for backup_dir in os.listdir(base_backupdir):
        backup = DeviceBackup(base_backupdir + backup_dir)
        if backup.is_valid():
            yield backup

#----------------------------------------------------------------------
# Individual command implementation and main function
#----------------------------------------------------------------------

class Program:
    def import_to_simulator(self, certificate_filepath, truststore_filepath=None):
        cert = Certificate()
        cert.load_PEMfile(certificate_filepath)
        print cert.get_subject()
        if truststore_filepath:
            tstore = TrustStore(truststore_filepath)
            tstore.add_certificate(cert)
            return
        for simulator in ios_simulators():
            print "Importing to " + simulator.truststore_file
            tstore = TrustStore(simulator.truststore_file)
            tstore.add_certificate(cert)
    
    def addfromdump(self, dump_base_filename, truststore_filepath=None):
        if truststore_filepath:
            if query_yes_no("Import to " + truststore_filepath, "no") == "yes":
                tstore = TrustStore(truststore_filepath)
                tstore.import_certificate_data(dump_base_filename)
            return
        for simulator in ios_simulators():
            if query_yes_no("Import to " + simulator.title, "no") == "yes":
                print "Importing to " + simulator.truststore_file
                tstore = TrustStore(simulator.truststore_file)
                tstore.import_certificate_data(dump_base_filename)
    
    def list_simulator_trustedcertificates(self, truststore_filepath=None):
        if truststore_filepath:
            tstore = TrustStore(truststore_filepath)
            tstore.list_certificates()
            return
        for simulator in ios_simulators():
            tstore = TrustStore(simulator.truststore_file, simulator.title)
            tstore.list_certificates()
    
    def export_simulator_trustedcertificates(self, certificate_base_filename, mode_dump, truststore_filepath=None):
        if truststore_filepath:
            tstore = TrustStore(truststore_filepath)
            if mode_dump:
                tstore.export_certificates_data(certificate_base_filename)
            else:
                tstore.export_certificates(certificate_base_filename)
            return
        for simulator in ios_simulators():
            tstore = TrustStore(simulator.truststore_file, simulator.title)
            if mode_dump:
                tstore.export_certificates_data(certificate_base_filename + "_" + simulator.version)
            else:
                tstore.export_certificates(certificate_base_filename + "_" + simulator.version)
    
    def delete_simulator_trustedcertificates(self, truststore_filepath=None):
        if truststore_filepath:
            tstore = TrustStore(truststore_filepath)
            tstore.delete_certificates()
            return
        for simulator in ios_simulators():
            tstore = TrustStore(simulator.truststore_file, simulator.title)
            tstore.delete_certificates()
    
    def list_device_trustedcertificates(self):
        for backup in device_backups():
            tstore = TrustStore(backup.get_truststore_file(), backup.title)
            tstore.list_certificates()
    
    def export_device_trustedcertificates(self, certificate_base_filename, mode_dump):
        for backup in device_backups():
            tstore = TrustStore(backup.get_truststore_file(), backup.title)
            if mode_dump:
                tstore.export_certificates_data(certificate_base_filename + "_" + backup.device_name)
            else:
                tstore.export_certificates(certificate_base_filename + "_" + backup.device_name)
    
    def run(self):
        parser = argparse.ArgumentParser()
        group = parser.add_mutually_exclusive_group(required=True)
        group.add_argument("-l", "--list", help="list custom trusted certificates in IOS simulator", action="store_true")
        group.add_argument("-d", "--delete", help="delete custom trusted certificates in IOS simulator", action="store_true")
        group.add_argument("-a", "--add", help="specifies a certificate file in PEM format to import and add to the IOS simulator trusted list", dest='certificate_file')
        group.add_argument("-e", "--export", help="export custom trusted certificates from IOS simulator in PEM format. ", dest='export_base_filename')
        group.add_argument("--dump", help="dump custom trusted certificates records from IOS simulator. ", dest='dump_base_filename')
        group.add_argument("--addfromdump", help="add custom trusted certificates records to IOS simulator from dump file created with --dump. ", dest='adddump_base_filename')
        parser.add_argument("-t", "--truststore", help="specify the path of the IOS TrustStore.sqlite3 file to edit. The default is to select and prompt for each available version")
        parser.add_argument("-b", "--devicebackup", help="(experimental) select a device backup as the TrustStore.sqlite3 source for list or export", action="store_true")
        args = parser.parse_args()
        if args.truststore and not os.path.isfile(args.truststore):
            print "invalid file: ", args.truststore
            exit(1)
        if args.devicebackup:
            if args.list:
                self.list_device_trustedcertificates()
            elif args.export_base_filename:
                self.export_device_trustedcertificates(args.export_base_filename, False)
            elif args.dump_base_filename:
                self.export_device_trustedcertificates(args.dump_base_filename, True)
            else:
                print "option not supported"
        elif args.list:
            self.list_simulator_trustedcertificates(args.truststore)
        elif args.delete:
            self.delete_simulator_trustedcertificates(args.truststore)
        elif args.certificate_file:
            self.import_to_simulator(args.certificate_file, args.truststore)
        elif args.export_base_filename:
            self.export_simulator_trustedcertificates(args.export_base_filename, False, args.truststore)
        elif args.dump_base_filename:
            self.export_simulator_trustedcertificates(args.dump_base_filename, True, args.truststore)
        elif args.adddump_base_filename:
            self.addfromdump(args.adddump_base_filename, args.truststore)
        print

if __name__ == "__main__":
    program = Program()
    program.run()
