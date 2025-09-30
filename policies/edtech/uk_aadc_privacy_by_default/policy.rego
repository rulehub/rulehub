package rulehub.edtech.uk_aadc_privacy_by_default

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.aadc.privacy_by_default == false
	msg := "edtech.uk_aadc_privacy_by_default: High privacy by default for children; limit data collection"
}

deny contains msg if {
	input.controls["edtech.uk_aadc_privacy_by_default"] == false
	msg := "edtech.uk_aadc_privacy_by_default: Generic control failed"
}
