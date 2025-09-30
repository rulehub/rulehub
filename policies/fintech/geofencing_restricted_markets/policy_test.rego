package rulehub.fintech.geofencing_restricted_markets

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.geofencing_restricted_markets": true}}
}

test_denies_when_generic_control_flag_false if {
	count(deny) > 0 with input as {"controls": {"fintech.geofencing_restricted_markets": false}}
}
