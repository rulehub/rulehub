package rulehub.fintech.aml_geolocation_restrictions

# curated: add transaction.geo and restrictions.blocked_geos evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.aml_geolocation_restrictions": true}, "transaction": {"geo": "US"}, "restrictions": {"blocked_geos": ["IR", "KP"]}}
}

test_denies_when_transaction_geo_blocked if {
	count(deny) > 0 with input as {"controls": {"fintech.aml_geolocation_restrictions": true}, "transaction": {"geo": "IR"}, "restrictions": {"blocked_geos": ["IR", "KP"]}}
}
