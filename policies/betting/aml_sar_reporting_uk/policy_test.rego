package rulehub.betting.aml_sar_reporting_uk

# curated: align evidence field names with policy (suspicion, sar_filed)
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.aml_sar_reporting_uk": true}, "aml": {"suspicion": true, "sar_filed": true}}
}

test_denies_when_suspicion_and_sar_not_filed if {
	count(deny) > 0 with input as {"controls": {"betting.aml_sar_reporting_uk": true}, "aml": {"suspicion": true, "sar_filed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.aml_sar_reporting_uk": false}, "aml": {"suspicion": false, "sar_filed": true}}
}

# Additional deny-focused test: suspicion true but SAR not filed
test_denies_when_suspicion_and_sar_not_filed_extra if {
	count(deny) > 0 with input as {"controls": {"betting.aml_sar_reporting_uk": true}, "aml": {"suspicion": true, "sar_filed": false}}
}
