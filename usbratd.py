#!/usr/bin/python

import os
import yaml
import signal
import sys
import logging

logging.basicConfig(format = u'%(levelname)-8s [%(asctime)s] %(message)s', level = logging.DEBUG, filename = u'usbrat.log')

with open("usbrat.yml", 'r') as stream:
    conf = yaml.load(stream)

def attach_tokens():
    logging.info( u'Attaching tokens' )
    for user in conf:
        print("======= " + user + " =======")
        for usbgroup in conf[user]:
            print("= " + usbgroup +" =")
            print(conf[user][usbgroup]['vmid'])
            print(conf[user][usbgroup]['vlan'])
            for token in conf[user][usbgroup]['tokens']:
                print("- " + token)


def detach_tokens():
    logging.info( u'Detaching tokens' )
    sys.exit(0)

def int_signal_handler(signal, frame):
    logging.debug( u'INT signal received' )
    detach_tokens()

def hup_signal_handler(signal, frame):
    logging.debug( u'HUP signal received' )
    detach_tokens()

signal.signal(signal.SIGINT, int_signal_handler)
signal.signal(signal.SIGHUP, hup_signal_handler)

attach_tokens()
signal.pause()
