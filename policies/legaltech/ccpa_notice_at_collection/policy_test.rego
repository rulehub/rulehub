package rulehub.legaltech.ccpa_notice_at_collection

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ccpa_notice_at_collection": true}, "ccpa": {"notice_at_collection_provided": true}}
}

test_denies_when_ccpa_notice_at_collection_provided_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_notice_at_collection": true}, "ccpa": {"notice_at_collection_provided": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_notice_at_collection": false}, "ccpa": {"notice_at_collection_provided": true}}
}

# Edge case: control disabled; collection notice absent
test_denies_when_control_disabled_and_notice_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_notice_at_collection": true}, "ccpa": {"notice_at_collection_provided": false}}
}
