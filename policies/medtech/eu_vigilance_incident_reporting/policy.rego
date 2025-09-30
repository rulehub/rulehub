package rulehub.medtech.eu_vigilance_incident_reporting

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.eu.vigilance.process_defined == false
	msg := "medtech.eu_vigilance_incident_reporting: Report serious incidents and FSCA per MDR/IVDR timelines"
}

deny contains msg if {
	input.controls["medtech.eu_vigilance_incident_reporting"] == false
	msg := "medtech.eu_vigilance_incident_reporting: Generic control failed"
}
