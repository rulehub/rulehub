package rulehub.medtech.gdpr_art9_special_category_safeguards

# curated: include processing.high_risk trigger for DPIA path
test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.gdpr_art9_special_category_safeguards": true}, "gdpr": {"art9_condition_met": true}, "processing": {"high_risk": true}, "privacy": {"dpia_done": true}}
}

test_denies_when_gdpr_art9_condition_met_false if {
	count(deny) > 0 with input as {"controls": {"medtech.gdpr_art9_special_category_safeguards": true}, "gdpr": {"art9_condition_met": false}, "processing": {"high_risk": true}, "privacy": {"dpia_done": true}}
}

test_denies_when_privacy_dpia_done_false if {
	count(deny) > 0 with input as {"controls": {"medtech.gdpr_art9_special_category_safeguards": true}, "gdpr": {"art9_condition_met": true}, "processing": {"high_risk": true}, "privacy": {"dpia_done": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.gdpr_art9_special_category_safeguards": false}, "gdpr": {"art9_condition_met": true}, "processing": {"high_risk": false}, "privacy": {"dpia_done": true}}
}

# Edge case: Both GDPR and privacy conditions false
test_denies_when_both_gdpr_privacy_false if {
	count(deny) > 0 with input as {"controls": {"medtech.gdpr_art9_special_category_safeguards": true}, "gdpr": {"art9_condition_met": false}, "processing": {"high_risk": true}, "privacy": {"dpia_done": false}}
}
