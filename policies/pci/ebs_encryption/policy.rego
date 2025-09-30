package rulehub.pci.ebs_encryption

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["pci.ebs_encryption"] == false
	msg := "pci.ebs_encryption: EBS volume encryption not enforced"
}
