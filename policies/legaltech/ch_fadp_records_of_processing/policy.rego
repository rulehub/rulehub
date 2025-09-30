package rulehub.legaltech.ch_fadp_records_of_processing

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.privacy.ropa_up_to_date == false
	msg := "legaltech.ch_fadp_records_of_processing: Maintain records of processing activities (Art. 12)"
}

deny contains msg if {
	input.controls["legaltech.ch_fadp_records_of_processing"] == false
	msg := "legaltech.ch_fadp_records_of_processing: Generic control failed"
}
