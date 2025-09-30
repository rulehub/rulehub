package rulehub.k8s.ban_hostnetwork

test_allow_when_compliant if {
	allow with input as {"controls": {"k8s.ban_hostnetwork": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"k8s.ban_hostnetwork": false}}
}
