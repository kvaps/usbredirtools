#!/usr/bin/python

import os
import yaml
import sys
import logging
import argparse
import socket

parser = argparse.ArgumentParser(description='usbrat server (USBRedir ATtach) - attach and detach requested usbgroups to vm\'s ')

parser.add_argument('-a', '--addr', help='Address to listen', default='')
parser.add_argument('-p', '--port', help='Port to listen. Default to 4411.', type=int, default=4411)
parser.add_argument('-v', '--verbose', help='Enable verbose logging', action='store_true')
parser.add_argument('-l', '--logfile', help='Path to log file', default = None)

options=parser.parse_args()

def set_logging():

    root_logger = logging.getLogger()
    logging.basicConfig(format = u'%(levelname)-8s [%(asctime)s] %(message)s', filename = options.logfile)

    if options.verbose:
       root_logger.setLevel('DEBUG')
    else:
       root_logger.setLevel('INFO')

with open("usbrat.yml", 'r') as stream:
    conf = yaml.load(stream)


sock = socket.socket()
sock.bind((options.addr, options.port))
sock.listen(5)
conn, addr = sock.accept()
print(u'Connected', addr)

while True:
    data = conn.recv(1024)

    if not data:
        break
    conn.send(data.upper())
conn.close()

#def attach_tokens():
#    logging.info( u'Attaching tokens' )
#    for user in conf:
#        print("======= " + user + " =======")
#        for usbgroup in conf[user]:
#            print("= " + usbgroup +" =")
#            print(conf[user][usbgroup]['vmid'])
#            print(conf[user][usbgroup]['vlan'])
#            for token in conf[user][usbgroup]['tokens']:
#                print("- " + token)
#
#
#def detach_tokens():
#    logging.info( u'Detaching tokens' )
#    sys.exit(0)
#
#attach_tokens()
