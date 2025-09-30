package rulehub.medtech.iec_62366_usability_summative_eval

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.usability.summative_evaluation_done == false
	msg := "medtech.iec_62366_usability_summative_eval: Perform summative evaluation to demonstrate usability and risk control"
}

deny contains msg if {
	input.controls["medtech.iec_62366_usability_summative_eval"] == false
	msg := "medtech.iec_62366_usability_summative_eval: Generic control failed"
}
