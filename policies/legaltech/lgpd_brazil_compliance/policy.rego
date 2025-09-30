package rulehub.legaltech.lgpd_brazil_compliance

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.lgpd.compliant == false
	msg := "legaltech.lgpd_brazil_compliance: Comply with LGPD principles rights"
}

deny contains msg if {
	input.controls["legaltech.lgpd_brazil_compliance"] == false
	msg := "legaltech.lgpd_brazil_compliance: Generic control failed"
}
