package rulehub.fintech.pci_network_segmentation

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_network_segmentation.compliant == false
	msg := "fintech.pci_network_segmentation: PCI DSS control not compliant"
}
