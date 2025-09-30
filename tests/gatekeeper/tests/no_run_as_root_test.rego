package k8srunasnonroot

test_violation_when_not_set if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "bad"},
        "spec": {"containers": [{"name": "c", "image": "busybox"}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 1
}

test_no_violation_when_true if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "good"},
        "spec": {"containers": [{"name": "c", "image": "busybox", "securityContext": {"runAsNonRoot": true}}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 0
}
