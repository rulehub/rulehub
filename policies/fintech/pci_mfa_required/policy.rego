package rulehub.fintech.pci_mfa_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_mfa_required.compliant == false
	msg := "fintech.pci_mfa_required: PCI DSS control not compliant"
}
