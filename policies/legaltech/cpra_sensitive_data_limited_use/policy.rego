package rulehub.legaltech.cpra_sensitive_data_limited_use

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ccpa.spi_limited_use == false
	msg := "legaltech.cpra_sensitive_data_limited_use: Limit use of sensitive personal information"
}

deny contains msg if {
	input.controls["legaltech.cpra_sensitive_data_limited_use"] == false
	msg := "legaltech.cpra_sensitive_data_limited_use: Generic control failed"
}
