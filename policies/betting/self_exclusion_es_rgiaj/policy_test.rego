package rulehub.betting.self_exclusion_es_rgiaj

# curated

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.self_exclusion_es_rgiaj": true}, "player": {"in_rgiaj": false}, "session": {"blocked": true}}
}

test_denies_when_session_blocked_false if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_es_rgiaj": true}, "player": {"in_rgiaj": true}, "session": {"blocked": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_es_rgiaj": false}, "player": {"in_rgiaj": false}, "session": {"blocked": true}}
}

test_denies_when_player_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.self_exclusion_es_rgiaj": false}, "player": {"in_rgiaj": true}, "session": {"blocked": false}}
}
