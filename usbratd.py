#!/usr/bin/python

import os
import yaml
import sys
import logging
import argparse
import socket

parser = argparse.ArgumentParser(description=u'usbrat server (USBRedir ATtach) - attach and detach requested usbgroups to vm\'s ')

parser.add_argument('-a', '--addr', help=u'Address to listen', default='')
parser.add_argument('-p', '--port', help=u'Port to listen. Default to 4411.', type=int, default=4411)
parser.add_argument('-v', '--verbose', help=u'Enable verbose logging', action='store_true')
parser.add_argument('-l', '--logfile', help=u'Path to log file', default = None)

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

def set_socket():
    sock = socket.socket()
    sock.bind((options.addr, options.port))
    
    while True:
        sock.listen(1)
        conn, addr = sock.accept()
        logging.info( u'Connected ' + str(addr) )
        data = conn.recv(1024)
        data = data.decode("utf-8")

        logging.debug( u'Received ' + data )
        action, user, usbgroup = data.split(':',2)
        exec_usbgroup(action, user, usbgroup)
        

        logging.debug( u'Closing ' + str(addr) )
        conn.close()


def exec_usbgroup(action, req_user, req_usbgroup):
    logging.info( u'Attaching tokens' )
    user_found = False
    usbgroup_found = False

    for user in conf:
        if user == req_user:
            user_found = True
            for usbgroup in conf[user]:
                if usbgroup == req_usbgroup:
                    usbgroup_found = True
                    if action == 'A':
                        attach_tokens(user, usbgroup)
                    elif action == 'D':
                        detach_tokens(user, usbgroup)
    if user_found == False:
        logging.info( u'No user found: ' + req_user )
    if usbgroup_found == False:
        logging.info( u'No usbgroup found for ' +req_user + ': ' + req_usbgroup )
            
    

def attach_tokens(user, usbgroup):
    print( u'vmid = ', conf[user][usbgroup]['vmid'])
    print( u'vlan = ', conf[user][usbgroup]['vlan'])
    print( u'tokens:' )
    for token in conf[user][usbgroup]['tokens']:
        print("- " + token)
 
def detach_tokens(user, usbgroup):

    logging.info( u'Detaching tokens' )

set_logging()
set_socket()
