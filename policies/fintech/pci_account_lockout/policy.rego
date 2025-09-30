package rulehub.fintech.pci_account_lockout

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_account_lockout.compliant == false
	msg := "fintech.pci_account_lockout: PCI DSS control not compliant"
}
