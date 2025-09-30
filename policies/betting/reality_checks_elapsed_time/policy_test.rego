package rulehub.betting.reality_checks_elapsed_time

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.reality_checks_elapsed_time": true}, "session": {"reality_checks_enabled": true}}
}

test_denies_when_session_reality_checks_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.reality_checks_elapsed_time": true}, "session": {"reality_checks_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.reality_checks_elapsed_time": false}, "session": {"reality_checks_enabled": true}}
}

test_denies_when_session_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.reality_checks_elapsed_time": false}, "session": {"reality_checks_enabled": false}}
}
