#!/bin/bash

ns=$1

oc delete mcl -n $ns $ns

oc delete HostFirmwareSettings -n $ns --all

for s in $(oc get secret -n $ns -o name|grep bmc); do
  oc patch -n $ns $s --type=merge -p '{"metadata": {"finalizers":null}}'
done

for bmh in $(oc get bmh -n $ns -o name |grep $ns); do
  oc patch -n $ns $bmh --type=merge -p '{"metadata": {"finalizers":null}}'
done

oc delete ns $ns --force --grace-period=0