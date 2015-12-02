#!/usr/bin/python

import signal
import sys
import logging
import argparse

parser = argparse.ArgumentParser(description='usbrat (USBRedirATtach) utility - Sends commands for attach usbgroup and dettach it when exit to usbrat server.')

parser.add_argument('user@hostname', help='Username and hostname of usbrat server')
parser.add_argument('usbgroup', help='Name of usbgroup')
parser.add_argument('-p','--port', help='Description for foo argument')
parser.add_argument('-a','--attach', help='Attach and exit', action='store_true')
parser.add_argument('-d','--detach', help='Detach and exit', action='store_true')

options=vars(parser.parse_args())

def attach_tokens():
    logging.info( u'Attaching tokens' )
    signal.signal(signal.SIGINT, int_signal_handler)
    signal.signal(signal.SIGHUP, hup_signal_handler)

def detach_tokens():
    logging.info( u'Detaching tokens' )
    sys.exit(0)

def int_signal_handler(signal, frame):
    logging.debug( u'INT signal received' )
    detach_tokens()

def hup_signal_handler(signal, frame):
    logging.debug( u'HUP signal received' )
    detach_tokens()

#attach_tokens()
print(options)
print(options['user@hostname'])
