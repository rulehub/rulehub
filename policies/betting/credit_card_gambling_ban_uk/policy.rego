package rulehub.betting.credit_card_gambling_ban_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.payment.method == "credit_card"
	msg := "gambling.credit_card_gambling_ban_uk: Do not accept credit cards for gambling (incl. e-wallet pass-through)"
}

deny contains msg if {
	input.controls["betting.credit_card_gambling_ban_uk"] == false
	msg := "gambling.credit_card_gambling_ban_uk: Generic control failed"
}
