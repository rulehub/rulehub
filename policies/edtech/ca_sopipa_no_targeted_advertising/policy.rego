package rulehub.edtech.ca_sopipa_no_targeted_advertising

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ads.targeted_using_student_data == true
	msg := "edtech.ca_sopipa_no_targeted_advertising: Prohibit targeted advertising based on student data"
}

deny contains msg if {
	input.controls["edtech.ca_sopipa_no_targeted_advertising"] == false
	msg := "edtech.ca_sopipa_no_targeted_advertising: Generic control failed"
}
