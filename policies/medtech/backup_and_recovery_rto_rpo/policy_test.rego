package rulehub.medtech.backup_and_recovery_rto_rpo

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.backup_and_recovery_rto_rpo": true}, "backup": {"restore_tested_recently": true, "rpo_met": true, "rto_met": true}}
}

test_denies_when_backup_restore_tested_recently_false if {
	count(deny) > 0 with input as {"controls": {"medtech.backup_and_recovery_rto_rpo": true}, "backup": {"restore_tested_recently": false, "rpo_met": true, "rto_met": true}}
}

test_denies_when_backup_rpo_met_false if {
	count(deny) > 0 with input as {"controls": {"medtech.backup_and_recovery_rto_rpo": true}, "backup": {"restore_tested_recently": true, "rpo_met": false, "rto_met": true}}
}

test_denies_when_backup_rto_met_false if {
	count(deny) > 0 with input as {"controls": {"medtech.backup_and_recovery_rto_rpo": true}, "backup": {"restore_tested_recently": true, "rpo_met": true, "rto_met": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.backup_and_recovery_rto_rpo": false}, "backup": {"restore_tested_recently": true, "rpo_met": true, "rto_met": true}}
}

# Edge case: All backup conditions false
test_denies_when_all_backup_false if {
	count(deny) > 0 with input as {"controls": {"medtech.backup_and_recovery_rto_rpo": true}, "backup": {"restore_tested_recently": false, "rpo_met": false, "rto_met": false}}
}
