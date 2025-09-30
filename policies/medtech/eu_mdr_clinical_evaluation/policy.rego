package rulehub.medtech.eu_mdr_clinical_evaluation

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.mdr.clinical_eval_plan == false
	msg := "medtech.eu_mdr_clinical_evaluation: Clinical evaluation plan missing"
}

deny contains msg if {
	input.mdr.clinical_eval_report == false
	msg := "medtech.eu_mdr_clinical_evaluation: Clinical evaluation report missing"
}

deny contains msg if {
	input.controls["medtech.eu_mdr_clinical_evaluation"] == false
	msg := "medtech.eu_mdr_clinical_evaluation: Generic control failed"
}
