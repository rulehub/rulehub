package rulehub.igaming.geofencing_regulated_markets

# curated: use explicit geo codes + allowed_markets list
test_allow_when_compliant if {
	allow with input as {"controls": {"igaming.geofencing_regulated_markets": true}, "allowed_markets": ["GB", "SE"], "player": {"geo": "GB"}}
}

test_denies_when_player_geo_false if {
	count(deny) > 0 with input as {"controls": {"igaming.geofencing_regulated_markets": true}, "allowed_markets": ["GB", "SE"], "player": {"geo": "BR"}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"igaming.geofencing_regulated_markets": false}, "allowed_markets": ["GB", "SE"], "player": {"geo": "GB"}}
}

test_denies_when_control_disabled_and_player_geo_unallowed if {
	count(deny) > 0 with input as {"controls": {"igaming.geofencing_regulated_markets": false}, "allowed_markets": ["GB", "SE"], "player": {"geo": "BR"}}
}

# Auto-generated granular test for controls["betting.geofencing_regulated_markets"]
test_denies_when_controls_betting_geofencing_regulated_markets_failing if {
	some _ in deny with input as {"controls": {"igaming.geofencing_regulated_markets": false}, "allowed_markets": ["GB"], "player": {"geo": "GB"}}
}

# Edge cases mirroring betting
test_denies_when_allowed_markets_empty if {
	count(deny) > 0 with input as {"controls": {"igaming.geofencing_regulated_markets": true}, "allowed_markets": [], "player": {"geo": "GB"}}
}

test_allows_when_player_geo_empty if {
	allow with input as {"controls": {"igaming.geofencing_regulated_markets": true}, "allowed_markets": ["GB", "SE"], "player": {"geo": ""}}
}
