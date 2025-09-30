package rulehub.k8s.ban_hostnetwork

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.ban_hostnetwork"] == false
	msg := "k8s.ban_hostnetwork: hostNetwork usage not blocked"
}
