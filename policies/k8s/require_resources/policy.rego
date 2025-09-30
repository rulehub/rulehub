package rulehub.k8s.require_resources

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.require_resources"] == false
	msg := "k8s.require_resources: resource limits/requests not required"
}
