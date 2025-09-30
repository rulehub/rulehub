package rulehub.pci.iam_password_policy

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["pci.iam_password_policy"] == false
	msg := "pci.iam_password_policy: password policy controls not enforced"
}
