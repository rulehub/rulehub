package rulehub.medtech.fda_cybersecurity_524b_sbom

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.cyber.sbom_available == false
	msg := "medtech.fda_cybersecurity_524b_sbom: Software Bill of Materials (SBOM) not available"
}

deny contains msg if {
	input.cyber.vuln_mgmt_program == false
	msg := "medtech.fda_cybersecurity_524b_sbom: Vulnerability management program missing"
}

deny contains msg if {
	input.cyber.postmarket_process == false
	msg := "medtech.fda_cybersecurity_524b_sbom: Postmarket cybersecurity monitoring/response process missing"
}

deny contains msg if {
	input.controls["medtech.fda_cybersecurity_524b_sbom"] == false
	msg := "medtech.fda_cybersecurity_524b_sbom: Generic control failed"
}
