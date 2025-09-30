package rulehub.betting.session_time_limits_controls

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.session_time_limits_controls": true}, "limits": {"session_time_limit_enabled": true}}
}

test_denies_when_limits_session_time_limit_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.session_time_limits_controls": true}, "limits": {"session_time_limit_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.session_time_limits_controls": false}, "limits": {"session_time_limit_enabled": true}}
}

test_denies_when_limits_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.session_time_limits_controls": false}, "limits": {"session_time_limit_enabled": false}}
}
