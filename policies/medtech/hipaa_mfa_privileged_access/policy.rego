package rulehub.medtech.hipaa_mfa_privileged_access

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.security.mfa_privileged_enabled == false
	msg := "medtech.hipaa_mfa_privileged_access: Use MFA for privileged/system admin access to ePHI systems (addressable)"
}

deny contains msg if {
	input.controls["medtech.hipaa_mfa_privileged_access"] == false
	msg := "medtech.hipaa_mfa_privileged_access: Generic control failed"
}
