package rulehub.k8s.no_run_as_root

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.no_run_as_root"] == false
	msg := "k8s.no_run_as_root: root user not disallowed"
}
