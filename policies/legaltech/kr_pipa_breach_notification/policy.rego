package rulehub.legaltech.kr_pipa_breach_notification

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.severity == "serious"
	input.breach.notified == false
	msg := "legaltech.kr_pipa_breach_notification: Notify data subjects/authority upon breach per PIPA"
}

deny contains msg if {
	input.controls["legaltech.kr_pipa_breach_notification"] == false
	msg := "legaltech.kr_pipa_breach_notification: Generic control failed"
}
