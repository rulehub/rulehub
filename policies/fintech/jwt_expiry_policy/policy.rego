package rulehub.fintech.jwt_expiry_policy

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.jwt_expiry_policy"] == false
	msg := "fintech.jwt_expiry_policy: Generic fintech control failed"
}
