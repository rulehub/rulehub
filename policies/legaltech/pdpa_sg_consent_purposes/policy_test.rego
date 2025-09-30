package rulehub.legaltech.pdpa_sg_consent_purposes

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.pdpa_sg_consent_purposes": true}, "pdpa": {"sg_purposes_specified": true}}
}

test_denies_when_pdpa_sg_purposes_specified_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.pdpa_sg_consent_purposes": true}, "pdpa": {"sg_purposes_specified": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.pdpa_sg_consent_purposes": false}, "pdpa": {"sg_purposes_specified": true}}
}

test_denies_when_control_disabled_and_purposes_unspecified if {
	count(deny) > 0 with input as {"controls": {"legaltech.pdpa_sg_consent_purposes": false}, "pdpa": {"sg_purposes_specified": false}}
}
