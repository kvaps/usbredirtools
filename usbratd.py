#!/usr/bin/python

import os
import yaml
import sys
import logging
import argparse
import socket
import json
import subprocess

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


def check_attached(usbgroup, host, vmid):

    p = subprocess.Popen(["ssh", host, "qm monitor", str(vmid)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)

    p.stdin.write(b'info chardev')
    output = p.communicate()[0].decode('utf-8').split('\n')

    result = False
    for line in output:
        if 'filename=tcp' in line:
            if usbgroup in line:
                result = True
                break

    logging.debug( u'Check if ' + usbgroup + ' usbgroup already attached. Result: ' + str(result))

    return(result)

def exec_usbgroup(data):

    user_found = False
    usbgroup_found = False

    for user in conf['usbgroups']:
        if user == data['user']:
            user_found = True
            for usbgroup in conf['usbgroups'][user]:
                if usbgroup == data['usbgroup']:
                    usbgroup_found = True

                    host = conf['usbgroups'][user][usbgroup]['host']
                    vmid = conf['usbgroups'][user][usbgroup]['vmid']
                    #network = conf['usbgroups'][user][usbgroup]['network']
                    usbs = conf['usbgroups'][user][usbgroup]['usb']

                    if data['action'] == 'attach':
                        attach_usbgroup(user, usbgroup, host, vmid, usbs)
                    elif data['action'] == 'detach':
                        detach_usbgroup(user, usbgroup, host, vmid, usbs)

    if user_found == False:
        logging.info( u'No user found: ' + data['user'] )
    elif usbgroup_found == False:
            logging.info( u'No usbgroup found for ' + data['user'] + ': ' + data['usbgroup'] )
            
def attach_usbgroup(user, usbgroup, host, vmid, usbs):

    logging.info( u'Attaching ' + usbgroup + ' usbgroup, for ' + user )

    if check_attached(usbgroup, host, vmid) == True:
        logging.warn( u'Usbgroup ' + usb + u' already attached to ' + str(check['vmid']) + u', run detaching...')
        detach_usbgroup(user, usbgroup, host, vmid, usbs)


    for usb in usbs:
        chardev_name = usbgroup + '_' + usb
        device_name = usbgroup + '_' + usb

        logging.info( u'Attach ' + usb)
        print(vmid)
        print(device_name)
        print(chardev_name)
 
def detach_usbgroup(user, usbgroup, host, vmid, usbs):

    logging.info( u'Detaching ' + usbgroup + ', for ' + user )


    for usb in usbs:
            
        logging.info( u'Detach ' + usb)


options=parser.parse_args()

with open(options.config, 'r') as stream:
    conf = yaml.load(stream)
if not os.path.exists(options.data + '/usb'):
    os.makedirs(options.data + '/usb')

set_logging()
set_socket()

