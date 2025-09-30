package rulehub.fintech.travel_rule_compliance

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.travel_rule_compliance"] == false
	input.crypto.travel_rule_enforced == false
	msg := "fintech.travel_rule_compliance: Travel Rule not enforced"
}
