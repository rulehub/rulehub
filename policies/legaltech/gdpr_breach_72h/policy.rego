package rulehub.legaltech.gdpr_breach_72h

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.occurred
	input.breach.notified_supervisor_in_72h == false
	msg := "legaltech.gdpr_breach_72h: Notify supervisory authority ≤ 72h"
}

deny contains msg if {
	input.controls["legaltech.gdpr_breach_72h"] == false
	msg := "legaltech.gdpr_breach_72h: Generic control failed"
}
