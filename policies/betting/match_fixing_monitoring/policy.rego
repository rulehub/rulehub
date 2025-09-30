package rulehub.betting.match_fixing_monitoring

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.integrity.monitoring_enabled == false
	msg := "betting.match_fixing_monitoring: Integrity monitoring disabled"
}

deny contains msg if {
	c := input.controls["betting.match_fixing_monitoring"]
	c == false
	msg := "betting.match_fixing_monitoring: Generic control failed"
}
