package rulehub.fintech.ip_geolocation_consistency

# curated: include transaction.geo + restrictions.blocked_geos evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.ip_geolocation_consistency": true}, "transaction": {"geo": "US"}, "restrictions": {"blocked_geos": ["IR", "KP"]}}
}

test_denies_when_transaction_geo_blocked if {
	count(deny) > 0 with input as {"controls": {"fintech.ip_geolocation_consistency": true}, "transaction": {"geo": "IR"}, "restrictions": {"blocked_geos": ["IR", "KP"]}}
}
