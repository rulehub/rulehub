package rulehub.betting.credit_card_gambling_ban_uk

# curated: allow scenario shows non-credit payment; deny uses credit_card
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.credit_card_gambling_ban_uk": true}, "payment": {"method": "debit_card"}}
}

test_denies_when_payment_method_credit_card if {
	count(deny) > 0 with input as {"controls": {"betting.credit_card_gambling_ban_uk": true}, "payment": {"method": "credit_card"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.credit_card_gambling_ban_uk": false}, "payment": {"method": "debit_card"}}
}

# Additional deny-focused test: credit card payment method triggers deny
test_denies_when_payment_method_credit_card_extra if {
	count(deny) > 0 with input as {"controls": {"betting.credit_card_gambling_ban_uk": true}, "payment": {"method": "credit_card"}}
}
