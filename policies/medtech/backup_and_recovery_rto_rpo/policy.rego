package rulehub.medtech.backup_and_recovery_rto_rpo

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.backup.rto_met == false
	msg := "medtech.backup_and_recovery_rto_rpo: RTO not met"
}

deny contains msg if {
	input.backup.rpo_met == false
	msg := "medtech.backup_and_recovery_rto_rpo: RPO not met"
}

deny contains msg if {
	input.backup.restore_tested_recently == false
	msg := "medtech.backup_and_recovery_rto_rpo: Restore not recently tested"
}

deny contains msg if {
	input.controls["medtech.backup_and_recovery_rto_rpo"] == false
	msg := "medtech.backup_and_recovery_rto_rpo: Generic control failed"
}
