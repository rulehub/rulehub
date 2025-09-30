package rulehub.edtech.ct_student_data_privacy

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.vendor.contract_compliant == false
	msg := "edtech.ct_student_data_privacy: Vendor contract not compliant"
}

deny contains msg if {
	input.breach.occurred
	input.breach.notified == false
	msg := "edtech.ct_student_data_privacy: Breach occurred without required district notification"
}

deny contains msg if {
	input.controls["edtech.ct_student_data_privacy"] == false
	msg := "edtech.ct_student_data_privacy: Generic control failed"
}
