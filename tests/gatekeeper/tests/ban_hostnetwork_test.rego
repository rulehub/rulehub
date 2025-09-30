package k8sbanhostnetwork

test_violation_when_hostnetwork_true if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "bad"},
        "spec": {"hostNetwork": true, "containers": [{"name": "c", "image": "busybox"}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 1
}

test_no_violation_when_hostnetwork_false if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "good"},
        "spec": {"hostNetwork": false, "containers": [{"name": "c", "image": "busybox"}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 0
}
