#!/bin/sh

curl -H "Content-Type: application/json" --data '{"RegCode":"Badri", "HostName" : "TempTest123", "ProcessType":"1"}' http://10.1.4.104:6805/CertServer
