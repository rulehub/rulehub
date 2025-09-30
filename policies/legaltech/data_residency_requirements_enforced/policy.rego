package rulehub.legaltech.data_residency_requirements_enforced

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.data.residency_required
	allowed := input.data.allowed_regions
	input.data.storage_region != ""
	not input.data.storage_region in allowed
	msg := "legaltech.data_residency_requirements_enforced: Enforce residency per contract/regulation"
}

deny contains msg if {
	input.controls["legaltech.data_residency_requirements_enforced"] == false
	msg := "legaltech.data_residency_requirements_enforced: Generic control failed"
}
