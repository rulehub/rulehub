package rulehub.medtech.hitech_breach_notification_60d

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.breach.occurred == true
	input.breach.days_since > 60
	input.breach.notified == false
	msg := "medtech.hitech_breach_notification_60d: Breach >60 days without required notifications"
}

deny contains msg if {
	input.controls["medtech.hitech_breach_notification_60d"] == false
	msg := "medtech.hitech_breach_notification_60d: Generic control failed"
}
