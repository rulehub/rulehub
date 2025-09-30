package rulehub.medtech.hipaa_minimum_necessary

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.hipaa.privacy.minimum_necessary_enforced == false
	msg := "medtech.hipaa_minimum_necessary: Limit use/disclosure to minimum necessary"
}

deny contains msg if {
	input.controls["medtech.hipaa_minimum_necessary"] == false
	msg := "medtech.hipaa_minimum_necessary: Generic control failed"
}
