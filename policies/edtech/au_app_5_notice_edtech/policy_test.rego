package rulehub.edtech.au_app_5_notice_edtech

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.au_app_5_notice_edtech": true}, "notice": {"at_collection_provided": true}}
}

test_denies_when_notice_at_collection_provided_false if {
	count(deny) > 0 with input as {"controls": {"edtech.au_app_5_notice_edtech": true}, "notice": {"at_collection_provided": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.au_app_5_notice_edtech": false}, "notice": {"at_collection_provided": true}}
}

test_denies_when_notice_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.au_app_5_notice_edtech": false}, "notice": {"at_collection_provided": false}}
}

# Auto-generated granular test for controls["edtech.au_app_5_notice_edtech"]
test_denies_when_controls_edtech_au_app_5_notice_edtech_failing if {
	some _ in deny with input as {"controls": {}, "notice": {"at_collection_provided": true}, "controls[\"edtech": {"au_app_5_notice_edtech\"]": false}}
}
