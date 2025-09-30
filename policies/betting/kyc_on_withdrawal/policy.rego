package rulehub.betting.kyc_on_withdrawal

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.player.kyc_completed == false
	msg := "gambling.kyc_on_withdrawal: Complete KYC before processing withdrawals"
}

deny contains msg if {
	input.controls["betting.kyc_on_withdrawal"] == false
	msg := "gambling.kyc_on_withdrawal: Generic control failed"
}
