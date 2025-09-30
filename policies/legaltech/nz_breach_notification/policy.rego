package rulehub.legaltech.nz_breach_notification

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.severity == "serious"
	input.breach.notified == false
	msg := "legaltech.nz_breach_notification: Notify OPC affected individuals of notifiable privacy breach"
}

deny contains msg if {
	input.controls["legaltech.nz_breach_notification"] == false
	msg := "legaltech.nz_breach_notification: Generic control failed"
}
