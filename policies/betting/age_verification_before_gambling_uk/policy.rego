package rulehub.betting.age_verification_before_gambling_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.kyc.age_verified == false
	msg := "gambling.age_verification_before_gambling_uk: Verify age and identity before gambling/deposit"
}

deny contains msg if {
	input.controls["betting.age_verification_before_gambling_uk"] == false
	msg := "gambling.age_verification_before_gambling_uk: Generic control failed"
}
