package rulehub.betting.safer_gambling_interactions

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.safer_gambling_interactions": true}, "safer_gambling": {"proactive_interactions_enabled": true}}
}

test_denies_when_safer_gambling_proactive_interactions_enabled_false if {
	count(deny) > 0 with input as {"controls": {"betting.safer_gambling_interactions": true}, "safer_gambling": {"proactive_interactions_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.safer_gambling_interactions": false}, "safer_gambling": {"proactive_interactions_enabled": true}}
}

test_denies_when_proactive_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.safer_gambling_interactions": false}, "safer_gambling": {"proactive_interactions_enabled": false}}
}
