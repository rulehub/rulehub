package k8slimitcapabilities

test_violation_when_not_drop_all if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "bad"},
        "spec": {"containers": [{"name": "c", "image": "busybox", "securityContext": {"capabilities": {"drop": ["NET_RAW"]}}}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 1
}

test_no_violation_when_drop_all if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "good"},
        "spec": {"containers": [{"name": "c", "image": "busybox", "securityContext": {"capabilities": {"drop": ["ALL"]}}}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 0
}
