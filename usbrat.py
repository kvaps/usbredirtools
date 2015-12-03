#!/usr/bin/python

import signal
import sys
import logging
import argparse
import socket


parser = argparse.ArgumentParser(description='usbrat tool (USBRedir ATtach) - Send commands for attach usbgroup and dettach it when exit to usbrat server.')

parser.add_argument('-H', '--host', help=u'Hostname of usbrat server. Default to localhost', default='localhost')
parser.add_argument('-p', '--port', help=u'Port of usbrat server. Default to 4411.', type=int, default=4411)
parser.add_argument('-u', '--user', help=u'Your username on usbrat server', required=True)
parser.add_argument('-A', '--attach', help=u'Attach and exit', action='store_true')
parser.add_argument('-D', '--detach', help=u'Detach and exit', action='store_true')
parser.add_argument('-x', '--usbgroup', help=u'Name of attaching usbgroup', required=True)
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
    

def attach_tokens():
    logging.info( u'Attaching ' + options.usbgroup + ', for ' + options.user )
    data = bytes(u'A:' + options.usbgroup + u':' + options.user, 'utf-8')
    send_server(data)

def detach_tokens():
    logging.info( u'Detaching ' + options.usbgroup + ', for ' + options.user )
    data = bytes(u'D:' + options.usbgroup + u':' + options.user, 'utf-8')
    send_server(data)
    logging.debug( u'Program exited' )
    sys.exit(0)

def int_signal_handler(signal, frame):
    logging.debug( u'INT signal received' )
    detach_tokens()

def hup_signal_handler(signal, frame):
    logging.debug( u'HUP signal received' )
    detach_tokens()

def send_server(data):
    sock = socket.socket()
    sock.connect((options.host, options.port))
    logging.debug( u'Connected ' + options.host + ':' + str(options.port) )
    logging.debug( u'Send ' + data.decode('utf-8') )
    sock.send(data)
    result = sock.recv(1024).decode('utf-8')
    logging.info(result)
    sock.close()


set_logging()
logging.debug( u'Program started' )

if options.attach:
    attach_tokens()
    exit(0)

if options.detach:
    detach_tokens()
    exit(0)

attach_tokens()
signal.signal(signal.SIGINT, int_signal_handler)
signal.signal(signal.SIGHUP, hup_signal_handler)
signal.pause()
