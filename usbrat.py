#!/usr/bin/python

import signal
import sys
import logging
import argparse


parser = argparse.ArgumentParser(description='usbrat tool (USBRedir ATtach) - Send commands for attach usbgroup and dettach it when exit to usbrat server.')

parser.add_argument('-H', '--host', help='Hostname of usbrat server', required=True)
parser.add_argument('-p', '--port', help='Port of usbrat server')
parser.add_argument('-u', '--user', help='Your username on usbrat server', required=True)
parser.add_argument('-A', '--attach', help='Attach and exit', action='store_true')
parser.add_argument('-D', '--detach', help='Detach and exit', action='store_true')
parser.add_argument('-x', '--usbgroup', help='Name of attaching usbgroup', required=True)
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
    

def attach_tokens():
    logging.info( u'Attaching ' + options.usbgroup + ' usbgroup, for ' + options.user )

def detach_tokens():
    logging.info( u'Detaching ' + options.usbgroup + ' usbgroup, for ' + options.user )
    logging.debug( u'Program exited' )
    sys.exit(0)

def int_signal_handler(signal, frame):
    logging.debug( u'INT signal received' )
    detach_tokens()

def hup_signal_handler(signal, frame):
    logging.debug( u'HUP signal received' )
    detach_tokens()

set_logging()
logging.debug( u'Program started' )
attach_tokens()
signal.signal(signal.SIGINT, int_signal_handler)
signal.signal(signal.SIGHUP, hup_signal_handler)
signal.pause()
