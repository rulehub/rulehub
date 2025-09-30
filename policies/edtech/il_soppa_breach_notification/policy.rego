package rulehub.edtech.il_soppa_breach_notification

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.occurred
	input.breach.notified == false
	msg := "edtech.il_soppa_breach_notification: Notify within statutory timelines; notify parents and district"
}

deny contains msg if {
	input.controls["edtech.il_soppa_breach_notification"] == false
	msg := "edtech.il_soppa_breach_notification: Generic control failed"
}
