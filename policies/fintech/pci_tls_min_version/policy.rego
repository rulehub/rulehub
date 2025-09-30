package rulehub.fintech.pci_tls_min_version

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.system.pci.pci_tls_min_version.compliant == false
	msg := "fintech.pci_tls_min_version: PCI DSS control not compliant"
}
