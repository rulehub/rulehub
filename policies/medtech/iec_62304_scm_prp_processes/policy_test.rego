package rulehub.medtech.iec_62304_scm_prp_processes

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.iec_62304_scm_prp_processes": true}, "software": {"problem_resolution_defined": true, "scm_defined": true}}
}

test_denies_when_software_problem_resolution_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62304_scm_prp_processes": true}, "software": {"problem_resolution_defined": false, "scm_defined": true}}
}

test_denies_when_software_scm_defined_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62304_scm_prp_processes": true}, "software": {"problem_resolution_defined": true, "scm_defined": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62304_scm_prp_processes": false}, "software": {"problem_resolution_defined": true, "scm_defined": true}}
}

# Edge case: Both software conditions false
test_denies_when_both_software_false if {
	count(deny) > 0 with input as {"controls": {"medtech.iec_62304_scm_prp_processes": true}, "software": {"problem_resolution_defined": false, "scm_defined": false}}
}
