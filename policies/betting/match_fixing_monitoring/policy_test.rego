package rulehub.betting.match_fixing_monitoring

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.match_fixing_monitoring": true}, "integrity": {"monitoring_enabled": true}}
}

test_denies_when_integrity_monitoring_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.match_fixing_monitoring": true}, "integrity": {"monitoring_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.match_fixing_monitoring": false}, "integrity": {"monitoring_enabled": true}}
}

test_denies_when_monitoring_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.match_fixing_monitoring": false}, "integrity": {"monitoring_enabled": false}}
}
