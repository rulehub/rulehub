package rulehub.aml.txn_monitoring_thresholds

test_allow_when_compliant if {
	allow with input as {"controls": {"aml.txn_monitoring_thresholds": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"aml.txn_monitoring_thresholds": false}}
}
