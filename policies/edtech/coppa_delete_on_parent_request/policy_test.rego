package rulehub.edtech.coppa_delete_on_parent_request

# curated: align with policy's parent_requested_deletion field
test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.coppa_delete_on_parent_request": true}, "coppa": {"parent_requested_deletion": true, "deleted": true}, "child": {"age": 11}}
}

test_denies_when_parent_requested_deletion_and_not_deleted if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_delete_on_parent_request": true}, "coppa": {"parent_requested_deletion": true, "deleted": false}, "child": {"age": 11}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_delete_on_parent_request": false}, "coppa": {"parent_requested_deletion": true, "deleted": true}, "child": {"age": 11}}
}

test_denies_when_parent_requested_deletion_and_not_deleted_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.coppa_delete_on_parent_request": false}, "coppa": {"parent_requested_deletion": true, "deleted": false}, "child": {"age": 11}}
}
