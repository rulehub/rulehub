package rulehub.pci.https_only

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["pci.https_only"] == false
	msg := "pci.https_only: HTTPS enforcement not enabled"
}
