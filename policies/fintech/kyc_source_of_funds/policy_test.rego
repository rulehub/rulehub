package rulehub.fintech.kyc_source_of_funds

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.kyc_source_of_funds": true}, "kyc": {"sof_collected": true}}
}

test_denies_when_kyc_sof_collected_false if {
	count(deny) > 0 with input as {"controls": {"fintech.kyc_source_of_funds": true}, "kyc": {"sof_collected": false}}
}
