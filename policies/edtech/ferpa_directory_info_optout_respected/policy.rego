package rulehub.edtech.ferpa_directory_info_optout_respected

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.student.directory_opt_out
	input.directory_info.disclosed == true
	msg := "edtech.ferpa_directory_info_optout_respected: Honor directory information opt-out preferences"
}

deny contains msg if {
	input.controls["edtech.ferpa_directory_info_optout_respected"] == false
	msg := "edtech.ferpa_directory_info_optout_respected: Generic control failed"
}
