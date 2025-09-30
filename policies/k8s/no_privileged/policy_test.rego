package rulehub.k8s.no_privileged

test_allow_when_compliant if {
	allow with input as {"controls": {"k8s.no_privileged": true}, "kind": "Pod"}
}

test_denies_when_container_privileged if {
	count(deny) > 0 with input as {"controls": {"k8s.no_privileged": true}, "kind": "Pod", "spec": {"containers": [{"name": "test", "securityContext": {"privileged": true}}]}}
}

test_denies_when_pod_privileged if {
	count(deny) > 0 with input as {"controls": {"k8s.no_privileged": true}, "kind": "Pod", "spec": {"securityContext": {"privileged": true}}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"k8s.no_privileged": false}, "kind": "Pod"}
}

# Edge case: Both container and pod privileged
test_denies_when_both_privileged if {
	count(deny) > 0 with input as {"controls": {"k8s.no_privileged": true}, "kind": "Pod", "spec": {"containers": [{"name": "test", "securityContext": {"privileged": true}}], "securityContext": {"privileged": true}}}
}
