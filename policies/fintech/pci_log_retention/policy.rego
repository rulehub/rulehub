package rulehub.fintech.pci_log_retention

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_log_retention.compliant == false
	msg := "fintech.pci_log_retention: PCI DSS control not compliant"
}
