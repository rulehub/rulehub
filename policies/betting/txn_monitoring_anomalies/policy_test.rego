package rulehub.betting.txn_monitoring_anomalies

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.txn_monitoring_anomalies": true}, "aml": {"txn_monitoring_enabled": true}}
}

test_denies_when_aml_txn_monitoring_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.txn_monitoring_anomalies": true}, "aml": {"txn_monitoring_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.txn_monitoring_anomalies": false}, "aml": {"txn_monitoring_enabled": true}}
}

test_denies_when_aml_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.txn_monitoring_anomalies": false}, "aml": {"txn_monitoring_enabled": false}}
}

# Auto-generated granular test for controls["betting.txn_monitoring_anomalies"]
test_denies_when_controls_betting_txn_monitoring_anomalies_failing if {
	some _ in deny with input as {"controls": {}, "aml": {"txn_monitoring_enabled": true}, "controls[\"betting": {"txn_monitoring_anomalies\"]": false}}
}
