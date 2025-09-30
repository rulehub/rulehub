package rulehub.fintech.pci_https_only

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_https_only.compliant == false
	msg := "fintech.pci_https_only: PCI DSS control not compliant"
}
