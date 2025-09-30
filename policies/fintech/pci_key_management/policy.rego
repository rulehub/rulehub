package rulehub.fintech.pci_key_management

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_key_management.compliant == false
	msg := "fintech.pci_key_management: PCI DSS control not compliant"
}
