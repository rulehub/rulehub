package rulehub.pci.iam_password_policy

test_allow_when_compliant if {
	allow with input as {"controls": {"pci.iam_password_policy": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"pci.iam_password_policy": false}}
}
