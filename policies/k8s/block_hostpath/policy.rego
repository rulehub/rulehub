package rulehub.k8s.block_hostpath

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.block_hostpath"] == false
	msg := "k8s.block_hostpath: hostPath volumes not blocked"
}
