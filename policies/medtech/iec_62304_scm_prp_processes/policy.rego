package rulehub.medtech.iec_62304_scm_prp_processes

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.software.scm_defined == false
	msg := "medtech.iec_62304_scm_prp_processes: Software configuration management (SCM) process not defined"
}

deny contains msg if {
	input.software.problem_resolution_defined == false
	msg := "medtech.iec_62304_scm_prp_processes: Problem resolution / CAPA process not defined"
}

deny contains msg if {
	input.controls["medtech.iec_62304_scm_prp_processes"] == false
	msg := "medtech.iec_62304_scm_prp_processes: Generic control failed"
}
