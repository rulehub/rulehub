package rulehub.medtech.eu_ivdr_clinical_performance

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ivdr.performance_evaluation_done == false
	msg := "medtech.eu_ivdr_clinical_performance: Scientific validity, analytical and clinical performance evaluation"
}

deny contains msg if {
	input.controls["medtech.eu_ivdr_clinical_performance"] == false
	msg := "medtech.eu_ivdr_clinical_performance: Generic control failed"
}
