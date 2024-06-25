#    - lastTransitionTime: "2024-06-21T17:46:12Z"
#      message: 'Preconditions failed for payload loaded version="4.13.43" image="quay.io/openshift-release-dev/ocp-release@sha256:d0da3d9b016e6d693a61c9425598921b6d0da99c52cb0f3404f6dbc126149e5d":
#        Precondition "ClusterVersionUpgradeable" failed because of "AdminAckRequired":
#        Kubernetes 1.26 and therefore OpenShift 4.13 remove several APIs which require
#        admin consideration. Please see the knowledge article https://access.redhat.com/articles/6958394
#        for details and instructions.'
#      reason: PreconditionChecks
#      status: "False"
#      type: ReleaseAccepted

oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.12-kube-1.26-api-removals-in-4.13":"true"}}' --type=merge