package rulehub.fintech.pci_storage_encryption

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_storage_encryption.compliant == false
	msg := "fintech.pci_storage_encryption: PCI DSS control not compliant"
}
