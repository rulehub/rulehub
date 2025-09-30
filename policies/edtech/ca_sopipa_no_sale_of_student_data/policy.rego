package rulehub.edtech.ca_sopipa_no_sale_of_student_data

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.data.sold_student_info == true
	msg := "edtech.ca_sopipa_no_sale_of_student_data: Prohibit sale of student information"
}

deny contains msg if {
	input.controls["edtech.ca_sopipa_no_sale_of_student_data"] == false
	msg := "edtech.ca_sopipa_no_sale_of_student_data: Generic control failed"
}
