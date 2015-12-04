#!/usr/bin/python

import os
import yaml
import sys
import logging
import argparse
import socket
import json
import uuid

parser = argparse.ArgumentParser(description=u'usbrat server (USBRedir ATtach) - attach and detach requested usbgroups to vm\'s ')

parser.add_argument('-a', '--addr', help=u'Address to listen', default='')
parser.add_argument('-p', '--port', help=u'Port to listen. Default to 4411.', type=int, default=4411)
parser.add_argument('-v', '--verbose', help=u'Enable verbose logging', action='store_true')
parser.add_argument('-l', '--log', help=u'Path to log file', default = None)
parser.add_argument('-c', '--config', help=u'Path to config. Default to usbratd.yml', default = u'usbratd.yml')

options=parser.parse_args()

def set_logging():

    root_logger = logging.getLogger()
    logging.basicConfig(format = u'%(levelname)-8s [%(asctime)s] %(message)s', filename = options.log)

    if options.verbose:
       root_logger.setLevel('DEBUG')
    else:
       root_logger.setLevel('INFO')

with open(options.config, 'r') as stream:
    conf = yaml.load(stream)

def set_socket():
    sock = socket.socket()
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((options.addr, options.port))

    while True:
        sock.listen(1)
        conn, addr = sock.accept()
        logging.info( u'Connected ' + str(addr) )
        data = conn.recv(1024)
        data = data.decode("utf-8")
        logging.debug( u'Received ' + data )
        data = json.loads(data)

        exec_usbgroup(data)
        
        logging.debug( u'Closing ' + str(addr) )
        conn.close()


def check_usbgroup(user, usbgroup):
    logging.debug( u'Checking ' + usbgroup + ', for ' + user )
    
    result = {'attached': None}
    #result = {'attached': True, 'vmid': 123 }

    result = json.dumps(result)
    
    logging.debug( u'Checking result ' + usbgroup + ', for ' + user + ' ' + result)
    return

def exec_usbgroup(data):
    user_found = False
    usbgroup_found = False
    group_attached = False

    for user in conf['usbgroups']:
        if user == data['user']:
            user_found = True
            for usbgroup in conf['usbgroups'][user]:
                if usbgroup == data['usbgroup']:
                    usbgroup_found = True

                    check=check_usbgroup(user, usbgroup)

                    if data['action'] == 'attach':
                        attach_usbgroup(user, usbgroup)
                    elif data['action'] == 'detach':
                        detach_usbgroup(user, usbgroup)
    if user_found == False:
        logging.info( u'No user found: ' + data['user'] )
    elif usbgroup_found == False:
            logging.info( u'No usbgroup found for ' +data['user'] + ': ' + data['usbgroup'] )
            
def gen_name(usbgroup, usb):
    short_uuid = str(uuid.uuid4())[:8]
    return usbgroup + '_' + usb + '_' + short_uuid

def attach_usbgroup(user, usbgroup):

    logging.info( u'Attaching ' + usbgroup + ', for ' + user )

    vmid = conf['usbgroups'][user][usbgroup]['vmid']
    network = conf['usbgroups'][user][usbgroup]['network']
    usbs = conf['usbgroups'][user][usbgroup]['usb']

    logging.debug( u'Connecting to vmid: ' + str(vmid))

    for usb in usbs:
        name=gen_name(usbgroup, usb)
        logging.info( u'Attaching ' + usb + u' as ' + name)
 
def detach_usbgroup(user, usbgroup):

    logging.info( u'Detaching ' + usbgroup + ', for ' + user )

set_logging()
set_socket()

