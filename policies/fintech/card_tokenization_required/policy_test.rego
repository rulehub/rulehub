package rulehub.fintech.card_tokenization_required

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.card_tokenization_required": true}, "payments": {"card_tokenized": true}}
}

test_denies_when_payments_card_tokenized_false if {
	count(deny) > 0 with input as {"controls": {"fintech.card_tokenization_required": true}, "payments": {"card_tokenized": false}}
}
