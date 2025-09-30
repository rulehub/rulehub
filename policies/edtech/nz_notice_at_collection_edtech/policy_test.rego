package rulehub.edtech.nz_notice_at_collection_edtech

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.nz_notice_at_collection_edtech": true}, "notice": {"at_collection_provided": true}}
}

test_denies_when_notice_at_collection_provided_false if {
	count(deny) > 0 with input as {"controls": {"edtech.nz_notice_at_collection_edtech": true}, "notice": {"at_collection_provided": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.nz_notice_at_collection_edtech": false}, "notice": {"at_collection_provided": true}}
}

test_denies_when_notice_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.nz_notice_at_collection_edtech": false}, "notice": {"at_collection_provided": false}}
}
