package rulehub.fintech.proof_of_reserves_reporting

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.proof_of_reserves_reporting"] == false
	msg := "fintech.proof_of_reserves_reporting: Generic fintech control failed"
}
