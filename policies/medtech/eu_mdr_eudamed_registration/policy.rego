package rulehub.medtech.eu_mdr_eudamed_registration

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.mdr.eudamed_registered == false
	msg := "medtech.eu_mdr_eudamed_registration: Register economic operators/devices in EUDAMED"
}

deny contains msg if {
	input.controls["medtech.eu_mdr_eudamed_registration"] == false
	msg := "medtech.eu_mdr_eudamed_registration: Generic control failed"
}
