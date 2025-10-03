package rulehub.legaltech.gdpr_dsar_timeline_30d

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_dsar_timeline_30d": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_dsar_timeline_30d": false}}
}

test_denies_when_request_open_over_30_days if {
	count(deny) > 0 with input as {
		"dsar": {"request_open_days": 45},
		"controls": {"legaltech.gdpr_dsar_timeline_30d": true},
	}
}

test_denies_when_control_disabled_and_request_open_over_30_days if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_dsar_timeline_30d": false}, "dsar": {"request_open_days": 45}}
}

# Auto-generated granular test for controls["legaltech.gdpr_dsar_timeline_30d"]
test_denies_when_controls_legaltech_gdpr_dsar_timeline_30d_failing if {
	some _ in deny with input as {"controls": {}, "dsar": {"request_open_days": true}, "controls[\"legaltech": {"gdpr_dsar_timeline_30d\"]": false}}
}
