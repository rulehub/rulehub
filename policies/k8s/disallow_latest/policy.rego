package rulehub.k8s.disallow_latest

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["k8s.disallow_latest"] == false
	msg := "k8s.disallow_latest: latest tag usage not prevented"
}
