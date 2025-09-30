package rulehub.pci.https_only

test_allow_when_compliant if {
	allow with input as {"controls": {"pci.https_only": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"pci.https_only": false}}
}
