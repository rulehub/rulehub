package rulehub.legaltech.lgpd_brazil_compliance

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.lgpd_brazil_compliance": true}, "lgpd": {"compliant": true}}
}

test_denies_when_lgpd_compliant_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.lgpd_brazil_compliance": true}, "lgpd": {"compliant": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.lgpd_brazil_compliance": false}, "lgpd": {"compliant": true}}
}

test_denies_when_control_disabled_and_lgpd_noncompliant if {
	count(deny) > 0 with input as {"controls": {"legaltech.lgpd_brazil_compliance": false}, "lgpd": {"compliant": false}}
}

# Auto-generated granular test for controls["legaltech.lgpd_brazil_compliance"]
test_denies_when_controls_legaltech_lgpd_brazil_compliance_failing if {
	some _ in deny with input as {"controls": {}, "lgpd": {"compliant": true}, "controls[\"legaltech": {"lgpd_brazil_compliance\"]": false}}
}
