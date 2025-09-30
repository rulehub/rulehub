package rulehub.k8s.require_resources

test_allow_when_compliant if {
	allow with input as {"controls": {"k8s.require_resources": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"k8s.require_resources": false}}
}
