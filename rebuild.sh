#!/bin/bash

SERVERS=`openstack server list --project benchmark  -c ID -f value`

for server in ${SERVERS} ; do
  openstack server rebuild --image ubuntu_20.04_focal ${server} 
done
