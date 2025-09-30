package rulehub.legaltech.my_pdpa_retention_principle

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.data.retention_days > input.policy.retention.max_days
	msg := "legaltech.my_pdpa_retention_principle: Comply with retention principle (s.10)"
}

deny contains msg if {
	input.controls["legaltech.my_pdpa_retention_principle"] == false
	msg := "legaltech.my_pdpa_retention_principle: Generic control failed"
}
