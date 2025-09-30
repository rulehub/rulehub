package rulehub.fintech.kyc_source_of_wealth

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.kyc_source_of_wealth": true}, "kyc": {"sow_collected": true}}
}

test_denies_when_kyc_sow_collected_false if {
	count(deny) > 0 with input as {"controls": {"fintech.kyc_source_of_wealth": true}, "kyc": {"sow_collected": false}}
}
