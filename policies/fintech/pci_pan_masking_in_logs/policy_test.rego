package rulehub.fintech.pci_pan_masking_in_logs

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_pan_masking_in_logs": true}, "system": {"pci": {"pci_pan_masking_in_logs": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_pan_masking_in_logs_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_pan_masking_in_logs": true}, "system": {"pci": {"pci_pan_masking_in_logs": {"compliant": false}}}}
}
