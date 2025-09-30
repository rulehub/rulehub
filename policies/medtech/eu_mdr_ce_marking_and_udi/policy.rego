package rulehub.medtech.eu_mdr_ce_marking_and_udi

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.mdr.ce_marking == false
	msg := "medtech.eu_mdr_ce_marking_and_udi: CE marking missing"
}

deny contains msg if {
	input.mdr.udi_assigned == false
	msg := "medtech.eu_mdr_ce_marking_and_udi: UDI assignment missing"
}

deny contains msg if {
	input.controls["medtech.eu_mdr_ce_marking_and_udi"] == false
	msg := "medtech.eu_mdr_ce_marking_and_udi: Generic control failed"
}
