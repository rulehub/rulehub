package rulehub.fintech.aml_ongoing_monitoring

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_ongoing_monitoring": true}, "aml": {"ongoing_monitoring_enabled": true}}
}

test_denies_when_aml_ongoing_monitoring_enabled_false if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_ongoing_monitoring": true}, "aml": {"ongoing_monitoring_enabled": false}}
}
