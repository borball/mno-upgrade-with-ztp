# MNO Upgrade with ZTP

This repo record the procedure and manifests used when upgrading a Multiple Node Openshift(MNO) cluster with Openshift 
Data Foundation(ODF) installed from EUS-4.12 to EUS-4.14.

## Hub cluster

We used a Single Node Openshift (SNO) instance to act as a RH ACM/ZTP hub, more information can be found [here](hub.md).

## Spoke cluster

We used 6 KVM instances to simulate the baremetal servers, on top of those we installed OCP 4.12 and ran the upgrade through 
ZTP policies with TALM operator. 
More information can be found [here](spoke.md).

## Policies

We prepared two set of policies for OCP 4.12 and OCP 4.14. For a fresh-installed cluster those policies can be bound with cluster label 'config-version: 4.12'
or 'config-version: 4.14'. 

We also prepared a set of policies to handle the cluster/operator upgrade. 
Our target for the cluster upgraded from 4.12 to 4.14 is that the 4.14 policies shall be compliant on the cluster without special changes.
The idea to drive the upgrade is to modify the cluster label with steps below: 

- (initial state) config-version: 4.12
- (upgrade to 4.13) config-version: upgrade-to-4.13
- (upgrade to 4.14) config-version: upgrade-to-4.14
- (post upgrade) config-version: 4.14

## Upgrade

We used ZTP/TALM to upgrade the cluster, following were the high level steps. 

### Before upgrade

The cluster had been installed with ZTP, and it had been bound with policies with cluster label: config-version: 4.12; 
all policies are compliant:

```shell
# oc get clusterversion
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.45   True        False         88m     Cluster version is 4.12.45

# oc get node
NAME                               STATUS   ROLES                  AGE    VERSION
master0.mno.outbound.vz.bos2.lab   Ready    control-plane,master   94m    v1.25.14+a52e8df
master1.mno.outbound.vz.bos2.lab   Ready    control-plane,master   115m   v1.25.14+a52e8df
master2.mno.outbound.vz.bos2.lab   Ready    control-plane,master   115m   v1.25.14+a52e8df
worker0.mno.outbound.vz.bos2.lab   Ready    std,worker             96m    v1.25.14+a52e8df
worker1.mno.outbound.vz.bos2.lab   Ready    std,worker             96m    v1.25.14+a52e8df
worker2.mno.outbound.vz.bos2.lab   Ready    ht,worker              96m    v1.25.14+a52e8df

# oc get mcp
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
ht       rendered-ht-78fd887b512802edd40db34f993ee986       True      False      False      1              1                   1                     0                      84m
master   rendered-master-6199337060ed6568304e95c51de561ee   True      False      False      3              3                   3                     0                      107m
std      rendered-std-78fd887b512802edd40db34f993ee986      True      False      False      2              2                   2                     0                      84m
worker   rendered-worker-78fd887b512802edd40db34f993ee986   True      False      False      0              0                   0                     0                      107m

# oc get policy -n mno
NAME                                                REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-common.cluster-version-4.12-config-policy       inform               Compliant          87m
ztp-common.mcp-4.12-mcp-policy                      inform               Compliant          87m
ztp-common.odf-config-4.12-odf-config               inform               Compliant          87m
ztp-common.operator-subs-4.12-catalog-policy        inform               Compliant          87m
ztp-common.operator-subs-4.12-subscription-policy   inform               Compliant          87m
```

ODF was installed/setup properly with ZTP policies:

```shell
# oc get storageclusters.ocs.openshift.io -A
NAMESPACE           NAME                 AGE   PHASE   EXTERNAL   CREATED AT             VERSION
openshift-storage   ocs-storagecluster   85m   Ready              2024-06-28T16:19:29Z   4.12.0

# oc get storageclass
NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   82m
ocs-storagecluster-ceph-rgw   openshift-storage.ceph.rook.io/bucket   Delete          Immediate              false                  85m
ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   82m
odf-localdisk                 kubernetes.io/no-provisioner            Delete          WaitForFirstConsumer   false                  85m
openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         Delete          Immediate              false                  81m

# oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name) ceph -s
  cluster:
    id:     acda18aa-5fe1-4458-828a-cbe40a7e604b
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum a,b,c (age 84m)
    mgr: a(active, since 83m)
    mds: 1/1 daemons up, 1 hot standby
    osd: 3 osds: 3 up (since 83m), 3 in (since 83m)
    rgw: 1 daemon active (1 hosts, 1 zones)

  data:
    volumes: 1/1 healthy
    pools:   12 pools, 353 pgs
    objects: 466 objects, 143 MiB
    usage:   522 MiB used, 449 GiB / 450 GiB avail
    pgs:     353 active+clean

  io:
    client:   2.6 KiB/s rd, 23 KiB/s wr, 3 op/s rd, 3 op/s wr
```

### Upgrade to 4.13
#### Update cluster label

Update the cluster label in the siteConfig to: config-version: upgrade-to-4.13. Commit/push to git repo.

After that the status of policies:

Hub:

```shell
# oc get policy -n ztp-upgrade
NAME                            REMEDIATION ACTION   COMPLIANCE STATE   AGE
upgrade-4.13-admin-ack          inform               NonCompliant       2d20h
upgrade-4.13-catalog-update     inform               NonCompliant       2d20h
upgrade-4.13-ocp-upgrade        inform               NonCompliant       2d20h
upgrade-4.13-operator-upgrade   inform               NonCompliant       45h
upgrade-4.13-pause-mcp          inform               NonCompliant       2d20h
upgrade-4.13-set-channel        inform               NonCompliant       2d20h
upgrade-4.14-admin-ack          inform                                  2d20h
upgrade-4.14-catalog-update     inform                                  2d20h
upgrade-4.14-ocp-upgrade        inform                                  2d20h
upgrade-4.14-operator-upgrade   inform                                  45h
```

Spoke:
```shell
# oc get policy -n mno
NAME                                        REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-upgrade.upgrade-4.13-admin-ack          inform               NonCompliant       14s
ztp-upgrade.upgrade-4.13-catalog-update     inform               NonCompliant       14s
ztp-upgrade.upgrade-4.13-ocp-upgrade        inform               NonCompliant       14s
ztp-upgrade.upgrade-4.13-operator-upgrade   inform               NonCompliant       14s
ztp-upgrade.upgrade-4.13-pause-mcp          inform               NonCompliant       14s
ztp-upgrade.upgrade-4.13-set-channel        inform               NonCompliant       14s
```
#### Create CGU

```shell
oc apply -f ztp/policies/upgrade/cgu-4.13.yaml
```

This will trigger the associated policies to be synced on the cluster so that upgrade will be happening.

Hub:
```shell
# oc get policy -n ztp-install -w
NAME                                               REMEDIATION ACTION   COMPLIANCE STATE   AGE
upgrade-4.13-upgrade-4.13-admin-ack-q74v5          enforce                                 14s
upgrade-4.13-upgrade-4.13-catalog-update-flcvp     enforce                                 14s
upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg        enforce                                 14s
upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce                                 14s
upgrade-4.13-upgrade-4.13-pause-mcp-t47gj          enforce                                 14s
upgrade-4.13-upgrade-4.13-set-channel-j6l4g        enforce              Compliant          14s
upgrade-4.13-upgrade-4.13-pause-mcp-t47gj          enforce                                 5m1s
upgrade-4.13-upgrade-4.13-pause-mcp-t47gj          enforce              NonCompliant       5m6s
upgrade-4.13-upgrade-4.13-pause-mcp-t47gj          enforce              Compliant          5m6s
upgrade-4.13-upgrade-4.13-admin-ack-q74v5          enforce                                 10m
upgrade-4.13-upgrade-4.13-admin-ack-q74v5          enforce              NonCompliant       10m
upgrade-4.13-upgrade-4.13-admin-ack-q74v5          enforce              Compliant          10m
upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg        enforce                                 15m
upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg        enforce              NonCompliant       15m
```

Spoke:
```shell
# oc get policy -n mno -w
NAME                                                      REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-install.upgrade-4.13-upgrade-4.13-pause-mcp-t47gj     enforce              Compliant          4m29s
ztp-install.upgrade-4.13-upgrade-4.13-set-channel-j6l4g   enforce              Compliant          9m29s
ztp-upgrade.upgrade-4.13-admin-ack                        inform               NonCompliant       12m
ztp-upgrade.upgrade-4.13-catalog-update                   inform               NonCompliant       12m
ztp-upgrade.upgrade-4.13-ocp-upgrade                      inform               NonCompliant       12m
ztp-upgrade.upgrade-4.13-operator-upgrade                 inform               NonCompliant       12m
ztp-upgrade.upgrade-4.13-pause-mcp                        inform               Compliant          12m
ztp-upgrade.upgrade-4.13-set-channel                      inform               Compliant          12m
ztp-install.upgrade-4.13-upgrade-4.13-admin-ack-q74v5     enforce                                 0s
ztp-install.upgrade-4.13-upgrade-4.13-admin-ack-q74v5     enforce                                 0s
ztp-install.upgrade-4.13-upgrade-4.13-admin-ack-q74v5     enforce              NonCompliant       4s
ztp-install.upgrade-4.13-upgrade-4.13-admin-ack-q74v5     enforce              Compliant          4s
ztp-upgrade.upgrade-4.13-admin-ack                        inform               Compliant          12m
ztp-install.upgrade-4.13-upgrade-4.13-set-channel-j6l4g   enforce              Compliant          10m
ztp-install.upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg   enforce                                 0s
ztp-install.upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg   enforce                                 0s
ztp-install.upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg   enforce              NonCompliant       2s
ztp-install.upgrade-4.13-upgrade-4.13-ocp-upgrade-bvppg   enforce              NonCompliant       2s
ztp-install.upgrade-4.13-upgrade-4.13-pause-mcp-t47gj     enforce              Compliant          10m
```

Upgrade in progress:

```shell
# oc get clusterversion -w
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.12.45   True        True          41s     Working towards 4.13.43: 106 of 843 done (12% complete), waiting on etcd, kube-apiserver
...
version   4.12.45   True        True          41m     Working towards 4.13.43: 682 of 843 done (80% complete), waiting on network
...
version   4.13.43   True        False         23s     Cluster version is 4.13.43
```

Operators upgrade in progress:

Hub:
```shell
# oc get policy -n ztp-install -w
NAME                                               REMEDIATION ACTION   COMPLIANCE STATE   AGE
upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce                                 90m
upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              NonCompliant       90m
upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              Compliant          92m

```

Spoke:
```shell
# oc get policy -n mno -w
NAME                                                         REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-upgrade.upgrade-4.13-operator-upgrade                    inform               NonCompliant       91m
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce                                 0s
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce                                 0s
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              NonCompliant       9s
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              NonCompliant       9s
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              NonCompliant       27s
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              NonCompliant       99s
ztp-install.upgrade-4.13-upgrade-4.13-operator-upgrade-zd99p   enforce              Compliant          117s
```



#### Validation

- All policies were compliant. 
- Cluster upgraded to 4.13.z.
- Operators upgraded to 4.13.z.
- ODF status healthy.

After all policies were compliant, OCP and operators upgrade to 4.13 completed.

Spoke:
```shell
# oc get policy -n mno
NAME                                        REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-upgrade.upgrade-4.13-admin-ack          inform               Compliant          96m
ztp-upgrade.upgrade-4.13-catalog-update     inform               Compliant          96m
ztp-upgrade.upgrade-4.13-ocp-upgrade        inform               Compliant          96m
ztp-upgrade.upgrade-4.13-operator-upgrade   inform               Compliant          96m
ztp-upgrade.upgrade-4.13-pause-mcp          inform               Compliant          96m
ztp-upgrade.upgrade-4.13-set-channel        inform               Compliant          96m
```

```shell
# oc get clusterversion
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.13.43   True        False         23s     Cluster version is 4.13.43

# oc get csv -A -o name |sort|uniq
clusterserviceversion.operators.coreos.com/local-storage-operator.v4.13.0-202405222206
clusterserviceversion.operators.coreos.com/mcg-operator.v4.13.9-rhodf
clusterserviceversion.operators.coreos.com/metallb-operator.v4.13.0-202405222206
clusterserviceversion.operators.coreos.com/ocs-operator.v4.13.9-rhodf
clusterserviceversion.operators.coreos.com/odf-csi-addons-operator.v4.13.9-rhodf
clusterserviceversion.operators.coreos.com/odf-operator.v4.13.9-rhodf
clusterserviceversion.operators.coreos.com/packageserver
clusterserviceversion.operators.coreos.com/sriov-network-operator.v4.13.0-202406060837

# oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name) ceph -s
  cluster:
    id:     acda18aa-5fe1-4458-828a-cbe40a7e604b
    health: HEALTH_OK

  services:
    mon: 3 daemons, quorum a,b,c (age 86s)
    mgr: a(active, since 69s)
    mds: 1/1 daemons up, 1 standby
    osd: 3 osds: 3 up (since 0.33835s), 3 in (since 3h)
    rgw: 1 daemon active (1 hosts, 1 zones)

  data:
    volumes: 1/1 healthy
    pools:   12 pools, 353 pgs
    objects: 471 objects, 183 MiB
    usage:   586 MiB used, 449 GiB / 450 GiB avail
    pgs:     353 active+clean

  io:
    client:   15 KiB/s wr, 0 op/s rd, 1 op/s wr
```

### Upgrade to 4.14
#### Update cluster label
Update the cluster label in the siteConfig to: config-version: upgrade-to-4.14. Commit/push to git repo.

After that the status of policies:

Hub:
```shell
# oc get policy -n ztp-upgrade
NAME                            REMEDIATION ACTION   COMPLIANCE STATE   AGE
upgrade-4.13-admin-ack          inform                                  3d22h
upgrade-4.13-catalog-update     inform                                  3d22h
upgrade-4.13-ocp-upgrade        inform                                  3d22h
upgrade-4.13-operator-upgrade   inform                                  3d
upgrade-4.13-pause-mcp          inform                                  3d22h
upgrade-4.13-set-channel        inform                                  3d22h
upgrade-4.14-admin-ack          inform               NonCompliant       3d22h
upgrade-4.14-catalog-update     inform               NonCompliant       3d22h
upgrade-4.14-ocp-upgrade        inform               NonCompliant       3d22h
upgrade-4.14-operator-upgrade   inform               NonCompliant       3d
```
Spoke:
```shell
# oc get policy -n mno
NAME                                        REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-upgrade.upgrade-4.14-admin-ack          inform               NonCompliant       22s
ztp-upgrade.upgrade-4.14-catalog-update     inform               NonCompliant       22s
ztp-upgrade.upgrade-4.14-ocp-upgrade        inform               NonCompliant       22s
ztp-upgrade.upgrade-4.14-operator-upgrade   inform               NonCompliant       22s
```
#### Create CGU

```shell
oc apply -f ztp/policies/upgrade/cgu-4.14.yaml
```

This will trigger the associated policies to be synced on the cluster so that upgrade will be happening.

Hub:
```shell
# oc get policy -n ztp-install -w
NAME                                               REMEDIATION ACTION   COMPLIANCE STATE   AGE
upgrade-4.14-upgrade-4.14-admin-ack-xsr6t          enforce              Compliant          58s
upgrade-4.14-upgrade-4.14-catalog-update-kt2nx     enforce                                 57s
upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t        enforce                                 58s
upgrade-4.14-upgrade-4.14-operator-upgrade-wr6vv   enforce                                 57s
upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t        enforce                                 5m1s
upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t        enforce              NonCompliant       5m2s
```
Spoke:
```shell
# oc get policy -n mno -w
NAME                                                      REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-install.upgrade-4.14-upgrade-4.14-admin-ack-xsr6t     enforce              Compliant          63s
ztp-upgrade.upgrade-4.14-admin-ack                        inform               Compliant          3m11s
ztp-upgrade.upgrade-4.14-catalog-update                   inform               NonCompliant       3m11s
ztp-upgrade.upgrade-4.14-ocp-upgrade                      inform               NonCompliant       3m11s
ztp-upgrade.upgrade-4.14-operator-upgrade                 inform               NonCompliant       3m11s
ztp-install.upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t   enforce                                 0s
ztp-install.upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t   enforce                                 0s
ztp-install.upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t   enforce              NonCompliant       1s
ztp-install.upgrade-4.14-upgrade-4.14-ocp-upgrade-8cd6t   enforce              NonCompliant       1s
```

Cluster upgrade in progress:
```shell
# oc get clusterversion
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.13.43   True        True          7m10s   Working towards 4.14.28: 118 of 860 done (13% complete), waiting on kube-apiserver
...
version   4.14.28   True        False         22m     Cluster version is 4.14.28
```

#### Validation
After all policies were compliant:

Spoke:
```shell
# oc get policy -n mno -w
NAME                                        REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-upgrade.upgrade-4.14-admin-ack          inform               Compliant          140m
ztp-upgrade.upgrade-4.14-catalog-update     inform               Compliant          140m
ztp-upgrade.upgrade-4.14-ocp-upgrade        inform               Compliant          140m
ztp-upgrade.upgrade-4.14-operator-upgrade   inform               Compliant          140m
```

The cluster was upgraded to 4.14:
```shell
version   4.14.28   True        False         22m     Cluster version is 4.14.28
```

Operators were upgraded to 4.14 as well:
```shell
# oc get csv -A -o name|sort|uniq
clusterserviceversion.operators.coreos.com/local-storage-operator.v4.14.0-202406180839
clusterserviceversion.operators.coreos.com/mcg-operator.v4.14.8-rhodf
clusterserviceversion.operators.coreos.com/metallb-operator.v4.14.0-202406180839
clusterserviceversion.operators.coreos.com/ocs-operator.v4.14.8-rhodf
clusterserviceversion.operators.coreos.com/odf-csi-addons-operator.v4.14.8-rhodf
clusterserviceversion.operators.coreos.com/odf-operator.v4.14.8-rhodf
clusterserviceversion.operators.coreos.com/packageserver
clusterserviceversion.operators.coreos.com/sriov-network-operator.v4.14.0-202405281408
```

### Post upgrade

We don't expect too many changes to happen in this step, since the cluster and operators have been upgraded to 4.14, we just want to make sure
the desired 4.14 policies become compliant as any other fresh-installed cluster through ZTP 4.14 policies.

#### Update cluster label
Update the cluster label: config-version: 4.14. Commit/push to git repo. 

After that the status of policies, you can see some policies were already compliant which is normal.

Hub:

```shell
# oc get policy -n ztp-common
NAME                                     REMEDIATION ACTION   COMPLIANCE STATE   AGE
cluster-version-4.12-config-policy       inform                                  7d21h
cluster-version-4.14-config-policy       inform               Compliant          8d
mcp-4.12-mcp-policy                      inform                                  7d21h
mcp-4.14-mcp-policy                      inform               Compliant          8d
odf-config-4.12-odf-config               inform                                  7d21h
odf-config-4.14-odf-config               inform               NonCompliant       8d
operator-subs-4.12-catalog-policy        inform                                  7d21h
operator-subs-4.12-subscription-policy   inform                                  7d21h
operator-subs-4.14-catalog-policy        inform               NonCompliant       7d21h
operator-subs-4.14-subscription-policy   inform               Compliant          8d
```

Spoke:
```shell
# oc get policy -n mno
NAME                                                REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-common.cluster-version-4.14-config-policy       inform               Compliant          20s
ztp-common.mcp-4.14-mcp-policy                      inform               Compliant          20s
ztp-common.odf-config-4.14-odf-config               inform               NonCompliant       20s
ztp-common.operator-subs-4.14-catalog-policy        inform               NonCompliant       20s
ztp-common.operator-subs-4.14-subscription-policy   inform               Compliant          20s
```
#### Create CGU

```shell
# oc apply -f ztp/policies/upgrade/cgu-4.14-post.yaml
```

#### Validation

Policies were compliant:

```shell
# oc get policy -n mno
NAME                                                REMEDIATION ACTION   COMPLIANCE STATE   AGE
ztp-common.cluster-version-4.14-config-policy       inform               Compliant          33m
ztp-common.mcp-4.14-mcp-policy                      inform               Compliant          33m
ztp-common.odf-config-4.14-odf-config               inform               Compliant          33m
ztp-common.operator-subs-4.14-catalog-policy        inform               Compliant          33m
ztp-common.operator-subs-4.14-subscription-policy   inform               Compliant          33m
```
