package rulehub.legaltech.ccpa_opt_out_enabled

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.ccpa.opt_out_enabled == false
	msg := "legaltech.ccpa_opt_out_enabled: Provide opt-out of sale/sharing"
}

deny contains msg if {
	input.controls["legaltech.ccpa_opt_out_enabled"] == false
	msg := "legaltech.ccpa_opt_out_enabled: Generic control failed"
}
