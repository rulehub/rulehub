package rulehub.legaltech.th_pdpa_breach_notify

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.severity == "serious"
	input.breach.notified == false
	msg := "legaltech.th_pdpa_breach_notify: Notify authority affected individuals under PDPA"
}

deny contains msg if {
	input.controls["legaltech.th_pdpa_breach_notify"] == false
	msg := "legaltech.th_pdpa_breach_notify: Generic control failed"
}
