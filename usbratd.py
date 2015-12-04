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
parser.add_argument('-D', '--data', help=u'Path to the data folder. Default to /var/lib/usbrat', default = u'/var/lib/usbrat')

def set_logging():

    root_logger = logging.getLogger()
    logging.basicConfig(format = u'%(levelname)-8s [%(asctime)s] %(message)s', filename = options.log)

    if options.verbose:
       root_logger.setLevel('DEBUG')
    else:
       root_logger.setLevel('INFO')

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
    
    usbs = conf['usbgroups'][user][usbgroup]['usb']

    for usb in usbs:
        with open(options.data + '/usb/' + usb, 'r') as stream:
            result = json.load(stream)

    print(result)
    #logging.debug( u'Checking result ' + usbgroup + ', for ' + user + ' ' + result)
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
            
def attach_usbgroup(user, usbgroup):

    logging.info( u'Attaching ' + usbgroup + ', for ' + user )

    vmid = conf['usbgroups'][user][usbgroup]['vmid']
    network = conf['usbgroups'][user][usbgroup]['network']
    usbs = conf['usbgroups'][user][usbgroup]['usb']

    logging.debug( u'Connecting to vmid: ' + str(vmid))

    for usb in usbs:

        chardev_name = usbgroup + '_' + usb + '_' + str(uuid.uuid4())[:8]
        device_name = usbgroup + '_' + usb

        # Write info about attached usb
        with open(options.data + '/usb/' + usb, 'w') as stream:
            stream.write(json.dumps({'vmid': vmid, 'chardev_name': chardev_name, 'device_name': device_name}))

        logging.info( u'Attaching ' + usb + u' as ')
 
def detach_usbgroup(user, usbgroup):

    logging.info( u'Detaching ' + usbgroup + ', for ' + user )

    vmid = conf['usbgroups'][user][usbgroup]['vmid']
    network = conf['usbgroups'][user][usbgroup]['network']
    usbs = conf['usbgroups'][user][usbgroup]['usb']

    for usb in usbs:
        # Remove info about attached usb
        os.remove(options.data + '/usb/' + usb)


options=parser.parse_args()

with open(options.config, 'r') as stream:
    conf = yaml.load(stream)
if not os.path.exists(options.data + '/usb'):
    os.makedirs(options.data + '/usb')

set_logging()
set_socket()

