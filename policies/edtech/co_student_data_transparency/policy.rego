package rulehub.edtech.co_student_data_transparency

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Individual deny conditions expanded (Rego v1 parser was unhappy with chained OR expression on one line)
deny contains msg if {
	input.public.data_inventory_published == false
	msg := "edtech.co_student_data_transparency: Public data inventory not published"
}

deny contains msg if {
	input.security.program_defined == false
	msg := "edtech.co_student_data_transparency: Security program not defined"
}

deny contains msg if {
	input.vendor.contract_compliant == false
	msg := "edtech.co_student_data_transparency: Vendor contracts not compliant"
}

deny contains msg if {
	input.controls["edtech.co_student_data_transparency"] == false
	msg := "edtech.co_student_data_transparency: Generic control failed"
}
