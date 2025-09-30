package rulehub.betting.reverse_withdrawal_ban_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.withdrawal.reverse_enabled == true
	msg := "gambling.reverse_withdrawal_ban_uk: Disable reverse withdrawals"
}

deny contains msg if {
	input.controls["betting.reverse_withdrawal_ban_uk"] == false
	msg := "betting.reverse_withdrawal_ban_uk: Generic control failed"
}
