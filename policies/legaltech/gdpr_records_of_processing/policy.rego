package rulehub.legaltech.gdpr_records_of_processing

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.gdpr.ropa_up_to_date == false
	msg := "legaltech.gdpr_records_of_processing: Maintain update RoPA (Art. 30)"
}

deny contains msg if {
	input.controls["legaltech.gdpr_records_of_processing"] == false
	msg := "legaltech.gdpr_records_of_processing: Generic control failed"
}
