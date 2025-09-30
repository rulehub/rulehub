package rulehub.legaltech.gdpr_retention_limit

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.data.retention_days > input.policy.gdpr.retention_max_days
	msg := "legaltech.gdpr_retention_limit: Retention periods not to exceed policy"
}

deny contains msg if {
	input.controls["legaltech.gdpr_retention_limit"] == false
	msg := "legaltech.gdpr_retention_limit: Generic control failed"
}
