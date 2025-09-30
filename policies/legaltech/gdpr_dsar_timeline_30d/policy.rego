package rulehub.legaltech.gdpr_dsar_timeline_30d

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.dsar.request_open_days > 30
	msg := "legaltech.gdpr_dsar_timeline_30d: Respond to DSAR within one month"
}

deny contains msg if {
	input.controls["legaltech.gdpr_dsar_timeline_30d"] == false
	msg := "legaltech.gdpr_dsar_timeline_30d: Generic control failed"
}
