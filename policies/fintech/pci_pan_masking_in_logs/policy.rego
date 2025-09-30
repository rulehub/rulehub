package rulehub.fintech.pci_pan_masking_in_logs

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_pan_masking_in_logs.compliant == false
	msg := "fintech.pci_pan_masking_in_logs: PCI DSS control not compliant"
}
