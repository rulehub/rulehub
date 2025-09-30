package rulehub.fintech.card_tokenization_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.payments.card_tokenized == false
	msg := "fintech.card_tokenization_required: Card not tokenized"
}
