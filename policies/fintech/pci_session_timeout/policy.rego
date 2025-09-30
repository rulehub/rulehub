package rulehub.fintech.pci_session_timeout

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_session_timeout.compliant == false
	msg := "fintech.pci_session_timeout: PCI DSS control not compliant"
}
