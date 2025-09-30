package rulehub.fintech.pci_file_integrity_monitoring

# curated
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_file_integrity_monitoring": true}, "system": {"pci": {"pci_file_integrity_monitoring": {"compliant": true}}}}
}

test_allows_when_control_enabled_but_non_compliant_deprecated_expectation_documenting_conjunction if {
	# Because deny requires BOTH control disabled and non-compliant, this scenario remains allowed
	allow with input as {"controls": {"fintech.pci_file_integrity_monitoring": true}, "system": {"pci": {"pci_file_integrity_monitoring": {"compliant": false}}}}
}

test_denies_when_control_disabled_and_non_compliant if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_file_integrity_monitoring": false}, "system": {"pci": {"pci_file_integrity_monitoring": {"compliant": false}}}}
}
