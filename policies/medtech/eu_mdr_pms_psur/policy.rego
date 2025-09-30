package rulehub.medtech.eu_mdr_pms_psur

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.mdr.pms_plan == false
	msg := "medtech.eu_mdr_pms_psur: Post-Market Surveillance plan missing"
}

deny contains msg if {
	input.mdr.psur_prepared == false
	msg := "medtech.eu_mdr_pms_psur: PSUR (Periodic Safety Update Report) not prepared for applicable device classes"
}

deny contains msg if {
	input.controls["medtech.eu_mdr_pms_psur"] == false
	msg := "medtech.eu_mdr_pms_psur: Generic control failed"
}
