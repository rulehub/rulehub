package rulehub.pci.storage_encryption

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["pci.storage_encryption"] == false
	msg := "pci.storage_encryption: storage encryption not enforced"
}
