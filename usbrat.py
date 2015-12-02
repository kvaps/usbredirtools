#!/usr/bin/python

import signal
import sys
import logging
import argparse

logging.basicConfig(format = u'%(levelname)-8s [%(asctime)s] %(message)s', level = logging.DEBUG, filename = u'usbrat.log')

parser = argparse.ArgumentParser(description='usbrat (USBRedirATtach) utility - Sends commands for attach usbgroup and dettach it when exit to usbrat server.')

parser.add_argument('-H', '--host', help='Hostname of usbrat server', required=True)
parser.add_argument('-p', '--port', help='Description for foo argument')
parser.add_argument('-u', '--user', help='Your username on usbrat server', required=True)
parser.add_argument('-a', '--attach', help='Attach and exit', action='store_true')
parser.add_argument('-d', '--detach', help='Detach and exit', action='store_true')
parser.add_argument('-x', '--usbgroup', help='Name of attaching usbgroup', required=True)

options=parser.parse_args()

def attach_tokens():
    logging.info( u'Attaching ' + options.usbgroup + ' usbgroup' )

def detach_tokens():
    logging.info( u'Detaching ' + options.usbgroup + ' usbgroup' )
    sys.exit(0)

def int_signal_handler(signal, frame):
    logging.debug( u'INT signal received' )
    detach_tokens()

def hup_signal_handler(signal, frame):
    logging.debug( u'HUP signal received' )
    detach_tokens()

attach_tokens()
signal.signal(signal.SIGINT, int_signal_handler)
signal.signal(signal.SIGHUP, hup_signal_handler)
signal.pause()
