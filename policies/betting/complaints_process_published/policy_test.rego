package rulehub.betting.complaints_process_published

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.complaints_process_published": true}, "complaints": {"process_published": true}}
}

test_denies_when_complaints_process_published_false if {
	count(deny) > 0 with input as {"controls": {"betting.complaints_process_published": true}, "complaints": {"process_published": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.complaints_process_published": false}, "complaints": {"process_published": true}}
}

# Additional deny-focused test: complaints process not published
test_denies_when_complaints_not_published_extra if {
	count(deny) > 0 with input as {"controls": {"betting.complaints_process_published": true}, "complaints": {"process_published": false}}
}

# Auto-generated granular test for controls["betting.complaints_process_published"]
test_denies_when_controls_betting_complaints_process_published_failing if {
	some _ in deny with input as {"controls": {}, "complaints": {"process_published": true}, "controls[\"betting": {"complaints_process_published\"]": false}}
}
