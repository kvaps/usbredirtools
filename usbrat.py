#!/usr/bin/python

import os
import yaml

with open("usbrat.yml", 'r') as stream:
    conf = yaml.load(stream)

for user in conf:
    print "======= " + user + " ======="
    for usbgroup in conf[user]:
        print "= " + usbgroup +" ="
        print conf[user][usbgroup]['vmid']
        print conf[user][usbgroup]['vlan']
        for token in conf[user][usbgroup]['tokens']:
            print "- " + token
