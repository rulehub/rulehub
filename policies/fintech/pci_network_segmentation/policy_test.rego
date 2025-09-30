package rulehub.fintech.pci_network_segmentation

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.pci_network_segmentation": true}, "system": {"pci": {"pci_network_segmentation": {"compliant": true}}}}
}

test_denies_when_system_pci_pci_network_segmentation_compliant_false if {
	count(deny) > 0 with input as {"controls": {"fintech.pci_network_segmentation": true}, "system": {"pci": {"pci_network_segmentation": {"compliant": false}}}}
}
