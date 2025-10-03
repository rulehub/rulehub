package rulehub.legaltech.gdpr_records_of_processing

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_records_of_processing": true}, "gdpr": {"ropa_up_to_date": true}}
}

test_denies_when_gdpr_ropa_up_to_date_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_records_of_processing": true}, "gdpr": {"ropa_up_to_date": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_records_of_processing": false}, "gdpr": {"ropa_up_to_date": true}}
}

test_denies_when_control_disabled_and_ropa_out_of_date if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_records_of_processing": false}, "gdpr": {"ropa_up_to_date": false}}
}

# Auto-generated granular test for controls["legaltech.gdpr_records_of_processing"]
test_denies_when_controls_legaltech_gdpr_records_of_processing_failing if {
	some _ in deny with input as {"controls": {}, "gdpr": {"ropa_up_to_date": true}, "controls[\"legaltech": {"gdpr_records_of_processing\"]": false}}
}
