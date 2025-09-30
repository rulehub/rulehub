package rulehub.k8s.limit_capabilities

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.limit_capabilities"] == false
	msg := "k8s.limit_capabilities: capability restrictions not enforced"
}
