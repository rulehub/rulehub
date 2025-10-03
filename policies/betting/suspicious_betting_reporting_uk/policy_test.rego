package rulehub.betting.suspicious_betting_reporting_uk

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.suspicious_betting_reporting_uk": true}, "integrity": {"suspicious_reported": true}}
}

test_denies_when_integrity_suspicious_reported_false if {
	count(deny) > 0 with input as {"controls": {"betting.suspicious_betting_reporting_uk": true}, "integrity": {"suspicious_reported": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.suspicious_betting_reporting_uk": false}, "integrity": {"suspicious_reported": true}}
}

test_denies_when_suspicious_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.suspicious_betting_reporting_uk": false}, "integrity": {"suspicious_reported": false}}
}

# Auto-generated granular test for controls["betting.suspicious_betting_reporting_uk"]
test_denies_when_controls_betting_suspicious_betting_reporting_uk_failing if {
	some _ in deny with input as {"controls": {}, "integrity": {"suspicious_reported": true}, "controls[\"betting": {"suspicious_betting_reporting_uk\"]": false}}
}
