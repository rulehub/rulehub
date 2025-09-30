package rulehub.edtech.edtech_access_least_privilege

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.edtech_access_least_privilege": true}, "security": {"least_privilege_enforced": true}}
}

test_denies_when_security_least_privilege_enforced_false if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_access_least_privilege": true}, "security": {"least_privilege_enforced": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_access_least_privilege": false}, "security": {"least_privilege_enforced": true}}
}

test_denies_when_least_privilege_and_control_fail if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_access_least_privilege": false}, "security": {"least_privilege_enforced": false}}
}
