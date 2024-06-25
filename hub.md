# Hub cluster

Hub cluster information:

- Single Node Openshift(SNO), 4.15.18
- Red Hat ACM: v2.10.3
- TALM Operator: v4.15.0
- Openshift GitOps operator: v1.12.3
- ZTP Site Generator: registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.15.0

```shell
# oc get node
NAME                        STATUS   ROLES                         AGE   VERSION
hub2.outbound.vz.bos2.lab   Ready    control-plane,master,worker   19m   v1.28.10+a2c84a5

# oc get clusterversion
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.15.18   True        False         3m2s    Cluster version is 4.15.18

# oc get csv -A -o name |sort |uniq
clusterserviceversion.operators.coreos.com/advanced-cluster-management.v2.10.3
clusterserviceversion.operators.coreos.com/openshift-gitops-operator.v1.12.3
clusterserviceversion.operators.coreos.com/topology-aware-lifecycle-manager.v4.15.0

# oc get argocd -n openshift-gitops openshift-gitops -o yaml |grep ztp-site-generate
image: registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.15.0
```