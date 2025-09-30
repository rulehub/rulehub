package rulehub.legaltech.gdpr_retention_limit

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_retention_limit": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_retention_limit": false}}
}

# Evidence-based deny: retention period exceeds allowed limit
test_denies_when_retention_exceeds_limit if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_retention_limit": true}, "data": {"retention_days": 400}, "policy": {"gdpr": {"retention_max_days": 365}}}
}

test_denies_when_control_disabled_and_retention_exceeds_limit if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_retention_limit": false}, "data": {"retention_days": 400}, "policy": {"gdpr": {"retention_max_days": 365}}}
}
