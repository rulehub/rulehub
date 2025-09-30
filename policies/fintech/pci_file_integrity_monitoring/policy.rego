package rulehub.fintech.pci_file_integrity_monitoring

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.pci_file_integrity_monitoring"] == false
	input.system.pci.pci_file_integrity_monitoring.compliant == false
	msg := "fintech.pci_file_integrity_monitoring: PCI DSS control not compliant"
}
