package rulehub.legaltech.tr_kvkk_verbis_registration

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.kvkk.verbis_registered == false
	msg := "legaltech.tr_kvkk_verbis_registration: Register as data controller in VERBIS when applicable"
}

deny contains msg if {
	input.controls["legaltech.tr_kvkk_verbis_registration"] == false
	msg := "legaltech.tr_kvkk_verbis_registration: Generic control failed"
}
