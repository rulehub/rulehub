package rulehub.betting.geofencing_regulated_markets

# curated: include allowed_markets context; use concrete geo strings
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.geofencing_regulated_markets": true}, "allowed_markets": ["GB", "SE"], "player": {"geo": "GB"}}
}

test_denies_when_player_geo_false if {
	count(deny) > 0 with input as {"controls": {"betting.geofencing_regulated_markets": true}, "allowed_markets": ["GB", "SE"], "player": {"geo": "BR"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.geofencing_regulated_markets": false}, "allowed_markets": ["GB", "SE"], "player": {"geo": "GB"}}
}

# Additional deny-focused test: player in disallowed market
test_denies_when_player_in_disallowed_market_extra if {
	count(deny) > 0 with input as {"controls": {"betting.geofencing_regulated_markets": true}, "allowed_markets": ["GB", "SE"], "player": {"geo": "BR"}}
}
