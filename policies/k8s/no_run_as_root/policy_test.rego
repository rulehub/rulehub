package rulehub.k8s.no_run_as_root

test_allow_when_compliant if {
	allow with input as {"controls": {"k8s.no_run_as_root": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"k8s.no_run_as_root": false}}
}
