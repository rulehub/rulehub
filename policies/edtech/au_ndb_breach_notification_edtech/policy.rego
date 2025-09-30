package rulehub.edtech.au_ndb_breach_notification_edtech

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.eligible
	input.breach.notified == false
	msg := "edtech.au_ndb_breach_notification_edtech: Notify OAIC and affected individuals of eligible data breaches"
}

deny contains msg if {
	input.controls["edtech.au_ndb_breach_notification_edtech"] == false
	msg := "edtech.au_ndb_breach_notification_edtech: Generic control failed"
}
