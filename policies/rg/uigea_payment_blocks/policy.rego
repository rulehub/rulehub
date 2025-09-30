package rulehub.rg.uigea_payment_blocks

deny contains msg if {
	input.customer.country == "US"
	input.game_type == "unlawful_internet_gambling"
	input.payment_method == "credit_card"
	msg := "UIGEA: payment via credit card must be blocked for unlawful internet gambling"
}
