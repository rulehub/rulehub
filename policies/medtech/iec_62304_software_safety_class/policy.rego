package rulehub.medtech.iec_62304_software_safety_class

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	# Trigger when safety class is not one of the allowed values A/B/C
	input.software.safety_class != "A"
	input.software.safety_class != "B"
	input.software.safety_class != "C"
	msg := "medtech.iec_62304_software_safety_class: Software safety class not one of A/B/C"
}

deny contains msg if {
	input.controls["medtech.iec_62304_software_safety_class"] == false
	msg := "medtech.iec_62304_software_safety_class: Generic control failed"
}
