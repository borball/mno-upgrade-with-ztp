# OCP Upgrade with ZTP

This repo record the procedure and manifests used when upgrading a multiple nodes cluster with ODF installed from 4.12 to 4.14.

## Hub cluster

We use a Single Node Openshift (SNO) instance to act as a ZTP hub, more information can be found [here](hub.md).

## Spoke cluster

We use 6 KVM instances to simulate the baremetal servers, on top of those we install OCP 4.12 with ZTP.  more information can be found [here](spoke.md).

## Upgrade

We use ZTP/TALM to upgrade the cluster, following are the high level steps. 

1. The current cluster has been bound with policies with cluster label: config-version: 4.12, and all policies are compliant.
2. Update the cluster label in the siteConfig to: config-version: upgrade-to-4.14.
3. The [policies](ztp/policies/upgrade) used to handle the upgrade will be created and their REMEDIATION ACTION is 'inform', state is 'NonCompliant'.
4. Create ClusterGroupUpgrade(CGU) [CR](ztp/policies/upgrade/cgu-4.13.yaml) to opt-in the 'informed' and 'non-compliant' policies for 4.13 upgrade.
5. The policies will start syncing on the cluster and cluster upgrade will be triggered later.
6. Create another ClusterGroupUpgrade(CGU) [CR](ztp/policies/upgrade/cgu-4.14.yaml) to opt-in the 'informed' and 'non-compliant' policies for 4.14 upgrade.
7. Once all the policies are compliant, the upgrade completes.
8. Update the cluster label in the siteConfig to: config-version: 4.14.
9. Create ClusterGroupUpgrade(CGU) [CR](ztp/policies/upgrade/cgu-4.14-post.yaml)
