package rulehub.edtech.edtech_audit_logs_student_record_access

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.edtech_audit_logs_student_record_access": true}, "logs": {"audit_trail_available": true}}
}

test_denies_when_logs_audit_trail_available_false if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_audit_logs_student_record_access": true}, "logs": {"audit_trail_available": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_audit_logs_student_record_access": false}, "logs": {"audit_trail_available": true}}
}

test_denies_when_audit_trail_missing_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.edtech_audit_logs_student_record_access": false}, "logs": {"audit_trail_available": false}}
}
