package rulehub.rg.au_audit_trails

default allow := false

allow if {
	count(deny) == 0
}

deny contains msg if {
	input.region == "AU"
	input.audit.trails_enabled == false
	msg := "AU iGaming: audit trails must be enabled and retained"
}

deny contains msg if {
	input.region == "AU"
	input.controls["rg.au_audit_trails"] == false
	msg := "rg.au_audit_trails: Generic control failed"
}
