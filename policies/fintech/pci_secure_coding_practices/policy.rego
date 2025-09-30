package rulehub.fintech.pci_secure_coding_practices

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_secure_coding_practices.compliant == false
	msg := "fintech.pci_secure_coding_practices: PCI DSS control not compliant"
}
