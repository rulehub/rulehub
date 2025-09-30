package k8simagepullalways

test_violation_when_not_always if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "bad"},
        "spec": {"containers": [{"name": "c", "image": "busybox", "imagePullPolicy": "IfNotPresent"}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 1
}

test_no_violation_when_always if {
  inp := {
    "review": {
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": "good"},
        "spec": {"containers": [{"name": "c", "image": "busybox", "imagePullPolicy": "Always"}]}
      }
    }
  }
  results := violation with input as inp
  count(results) == 0
}
