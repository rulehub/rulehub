package rulehub.legaltech.sa_pdpl_breach_notify

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.breach.severity == "serious"
	input.breach.notified == false
	msg := "legaltech.sa_pdpl_breach_notify: Notify authority data subjects per PDPL timelines"
}

deny contains msg if {
	input.controls["legaltech.sa_pdpl_breach_notify"] == false
	msg := "legaltech.sa_pdpl_breach_notify: Generic control failed"
}
