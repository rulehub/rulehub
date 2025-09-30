package rulehub.betting.aml_high_risk_country_restrictions

# curated: include customer.country and high_risk_list trigger
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.aml_high_risk_country_restrictions": true}, "customer": {"country": "GB"}, "aml": {"high_risk_list": ["IR", "KP"], "edd_applied": true}}
}

test_denies_when_aml_edd_applied_false if {
	count(deny) > 0 with input as {"controls": {"betting.aml_high_risk_country_restrictions": true}, "customer": {"country": "IR"}, "aml": {"high_risk_list": ["IR", "KP"], "edd_applied": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.aml_high_risk_country_restrictions": false}, "customer": {"country": "GB"}, "aml": {"high_risk_list": ["IR", "KP"], "edd_applied": true}}
}

# Extra deny-focused test: customer in high-risk list and EDD not applied
test_denies_when_customer_in_high_risk_and_no_edd if {
	count(deny) > 0 with input as {"controls": {"betting.aml_high_risk_country_restrictions": true}, "customer": {"country": "IR"}, "aml": {"high_risk_list": ["IR", "KP"], "edd_applied": false}}
}
