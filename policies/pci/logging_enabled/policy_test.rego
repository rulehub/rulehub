package rulehub.pci.logging_enabled

test_allow_when_compliant if {
	allow with input as {"controls": {"pci.logging_enabled": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"pci.logging_enabled": false}}
}
