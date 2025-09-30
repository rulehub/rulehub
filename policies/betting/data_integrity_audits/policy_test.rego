package rulehub.betting.data_integrity_audits

test_allow_when_compliant if {
	allow with input as {"controls": {"betting.data_integrity_audits": true}, "data": {"audit_passed": true}}
}

test_denies_when_data_audit_passed_false if {
	count(deny) > 0 with input as {"controls": {"betting.data_integrity_audits": true}, "data": {"audit_passed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.data_integrity_audits": false}, "data": {"audit_passed": true}}
}

# Additional deny-focused test: data audit failed triggers deny
test_denies_when_data_audit_failed_extra if {
	count(deny) > 0 with input as {"controls": {"betting.data_integrity_audits": true}, "data": {"audit_passed": false}}
}
