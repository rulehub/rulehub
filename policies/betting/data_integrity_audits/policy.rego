package rulehub.betting.data_integrity_audits

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.data.audit_passed == false
	msg := "betting.data_integrity_audits: Data provider audit failed"
}

deny contains msg if {
	c := input.controls["betting.data_integrity_audits"]
	c == false
	msg := "betting.data_integrity_audits: Generic control failed"
}
