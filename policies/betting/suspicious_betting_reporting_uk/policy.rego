package rulehub.betting.suspicious_betting_reporting_uk

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.integrity.suspicious_reported == false
	msg := "betting.suspicious_betting_reporting_uk: Suspicious betting not reported"
}

deny contains msg if {
	c := input.controls["betting.suspicious_betting_reporting_uk"]
	c == false
	msg := "betting.suspicious_betting_reporting_uk: Generic control failed"
}
