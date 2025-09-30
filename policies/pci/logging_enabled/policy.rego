package rulehub.pci.logging_enabled

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["pci.logging_enabled"] == false
	msg := "pci.logging_enabled: logging not enabled for in-scope systems"
}
