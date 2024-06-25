#- lastTransitionTime: "2024-06-21T19:08:01Z"
#  message: Kubernetes 1.27 and therefore OpenShift 4.14 remove several APIs which
#    require admin consideration. Please see the knowledge article https://access.redhat.com/articles/6958395
#    for details and instructions.
#  reason: AdminAckRequired
#  status: "False"
#  type: UpgradeableAdminAckRequired

oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.13-kube-1.27-api-removals-in-4.14":"true"}}' --type=merge