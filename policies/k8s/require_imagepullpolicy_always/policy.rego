package rulehub.k8s.require_imagepullpolicy_always

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.require_imagepullpolicy_always"] == false
	msg := "k8s.require_imagepullpolicy_always: ImagePullPolicy Always not enforced"
}
