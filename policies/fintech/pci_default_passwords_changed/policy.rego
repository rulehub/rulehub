package rulehub.fintech.pci_default_passwords_changed

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_default_passwords_changed.compliant == false
	msg := "fintech.pci_default_passwords_changed: PCI DSS control not compliant"
}
