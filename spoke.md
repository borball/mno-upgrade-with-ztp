# Spoke cluster

Spoke cluster information:

- Deployed through ZTP, initial version 4.12.45
  - [siteConfig](ztp/sites/mno.yaml)
  - [policies](ztp/policies/4.12)
- Multiple Nodes Openshift(MNO)
  - 3 masters + 3 workers
  - mcp master: 3 nodes
  - mcp std: 2 nodes
  - mcp ht: 1 node

- ODF installed on the cluster
- Other operators for test purpose:
  - SR-IOV
  - Local storage (Part of ODF)
  - MetalLB


Cluster status:
```shell
# oc get clusterversion
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.45   True        False         46m     Cluster version is 4.12.45

# oc get nodes
NAME                               STATUS   ROLES                  AGE   VERSION
master0.mno.outbound.vz.bos2.lab   Ready    control-plane,master   90m   v1.25.14+a52e8df
master1.mno.outbound.vz.bos2.lab   Ready    control-plane,master   90m   v1.25.14+a52e8df
master2.mno.outbound.vz.bos2.lab   Ready    control-plane,master   50m   v1.25.14+a52e8df
worker0.mno.outbound.vz.bos2.lab   Ready    std,worker             74m   v1.25.14+a52e8df
worker1.mno.outbound.vz.bos2.lab   Ready    std,worker             74m   v1.25.14+a52e8df
worker2.mno.outbound.vz.bos2.lab   Ready    ht,worker              74m   v1.25.14+a52e8df

# oc get mcp
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
ht       rendered-ht-2f263f3316c9f6bc9dbfc2165f71a760       True      False      False      1              1                   1                     0                      5m55s
master   rendered-master-a0ebe3d61c72b59a3338e9ecebf1627c   True      False      False      3              3                   3                     0                      84m
std      rendered-std-2f263f3316c9f6bc9dbfc2165f71a760      True      False      False      2              2                   2                     0                      83s
worker   rendered-worker-2f263f3316c9f6bc9dbfc2165f71a760   True      False      False      0              0                   0                     0                      84m

# oc get operator
NAME                                                      AGE
local-storage-operator.openshift-local-storage            46m
mcg-operator.openshift-storage                            41m
metallb-operator.metallb-system                           46m
ocs-operator.openshift-storage                            41m
odf-csi-addons-operator.openshift-storage                 41m
odf-operator.openshift-storage                            46m
sriov-network-operator.openshift-sriov-network-operator   46m

# oc get csv -A -o name |sort|uniq
clusterserviceversion.operators.coreos.com/local-storage-operator.v4.12.0-202405222205
clusterserviceversion.operators.coreos.com/mcg-operator.v4.12.13-rhodf
clusterserviceversion.operators.coreos.com/metallb-operator.4.12.0-202405291506
clusterserviceversion.operators.coreos.com/ocs-operator.v4.12.13-rhodf
clusterserviceversion.operators.coreos.com/odf-csi-addons-operator.v4.12.13-rhodf
clusterserviceversion.operators.coreos.com/odf-operator.v4.12.13-rhodf
clusterserviceversion.operators.coreos.com/packageserver
clusterserviceversion.operators.coreos.com/sriov-network-operator.v4.12.0-202405222205

# oc get policy -A
NAMESPACE   NAME                                                REMEDIATION ACTION   COMPLIANCE STATE   AGE
mno         ztp-common.cluster-version-4.12-config-policy       inform               Compliant          51m
mno         ztp-common.mcp-4.12-mcp-policy                      inform               Compliant          51m
mno         ztp-common.odf-config-4.12-odf-config               inform               Compliant          51m
mno         ztp-common.operator-subs-4.12-catalog-policy        inform               Compliant          51m
mno         ztp-common.operator-subs-4.12-subscription-policy   inform               Compliant          51m

```

ODF status:

```shell
# oc get storageclusters.ocs.openshift.io -A
NAMESPACE           NAME                 AGE     PHASE   EXTERNAL   CREATED AT             VERSION
openshift-storage   ocs-storagecluster   8m39s   Ready              2024-06-21T14:26:30Z   4.12.0

# oc get storageclass
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   6m42s
ocs-storagecluster-ceph-rgw   openshift-storage.ceph.rook.io/bucket   Delete          Immediate              false                  9m20s
ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   6m42s
odf-localdisk                 kubernetes.io/no-provisioner            Delete          WaitForFirstConsumer   false                  26m
openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         Delete          Immediate              false                  5m13s

# oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name) ceph -s
  cluster:
    id:     51ed6186-4721-4f8e-a620-ed945dc29e64
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum a,b,c (age 17m)
    mgr: a(active, since 16m)
    mds: 1/1 daemons up, 1 hot standby
    osd: 3 osds: 3 up (since 16m), 3 in (since 16m)
    rgw: 1 daemon active (1 hosts, 1 zones)

  data:
    volumes: 1/1 healthy
    pools:   12 pools, 353 pgs
    objects: 336 objects, 133 MiB
    usage:   373 MiB used, 450 GiB / 450 GiB avail
    pgs:     353 active+clean

  io:
    client:   853 B/s rd, 63 KiB/s wr, 1 op/s rd, 6 op/s wr
```