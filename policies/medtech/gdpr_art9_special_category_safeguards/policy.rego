package rulehub.medtech.gdpr_art9_special_category_safeguards

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Violations split into atomic checks for Rego v1 compatibility
deny contains msg if {
	input.gdpr.art9_condition_met == false
	msg := "medtech.gdpr_art9_special_category_safeguards: No valid Art. 9(2) condition documented for processing special category data"
}

deny contains msg if {
	input.processing.high_risk == true
	input.privacy.dpia_done == false
	msg := "medtech.gdpr_art9_special_category_safeguards: High-risk processing without a completed DPIA"
}

deny contains msg if {
	input.controls["medtech.gdpr_art9_special_category_safeguards"] == false
	msg := "medtech.gdpr_art9_special_category_safeguards: Generic control failed"
}
