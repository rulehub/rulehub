package rulehub.medtech.fda_cybersecurity_524b_sbom

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.fda_cybersecurity_524b_sbom": true}, "cyber": {"postmarket_process": true, "sbom_available": true, "vuln_mgmt_program": true}}
}

test_denies_when_cyber_postmarket_process_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_cybersecurity_524b_sbom": true}, "cyber": {"postmarket_process": false, "sbom_available": true, "vuln_mgmt_program": true}}
}

test_denies_when_cyber_sbom_available_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_cybersecurity_524b_sbom": true}, "cyber": {"postmarket_process": true, "sbom_available": false, "vuln_mgmt_program": true}}
}

test_denies_when_cyber_vuln_mgmt_program_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_cybersecurity_524b_sbom": true}, "cyber": {"postmarket_process": true, "sbom_available": true, "vuln_mgmt_program": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_cybersecurity_524b_sbom": false}, "cyber": {"postmarket_process": true, "sbom_available": true, "vuln_mgmt_program": true}}
}

# Edge case: All cyber conditions false
test_denies_when_all_cyber_false if {
	count(deny) > 0 with input as {"controls": {"medtech.fda_cybersecurity_524b_sbom": true}, "cyber": {"postmarket_process": false, "sbom_available": false, "vuln_mgmt_program": false}}
}
