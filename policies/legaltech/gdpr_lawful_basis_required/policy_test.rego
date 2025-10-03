package rulehub.legaltech.gdpr_lawful_basis_required

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.gdpr_lawful_basis_required": true}, "gdpr": {"lawful_basis_documented": true}}
}

test_denies_when_gdpr_lawful_basis_documented_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_lawful_basis_required": true}, "gdpr": {"lawful_basis_documented": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_lawful_basis_required": false}, "gdpr": {"lawful_basis_documented": true}}
}

test_denies_when_control_disabled_and_lawful_basis_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.gdpr_lawful_basis_required": false}, "gdpr": {"lawful_basis_documented": false}}
}

# Auto-generated granular test for controls["legaltech.gdpr_lawful_basis_required"]
test_denies_when_controls_legaltech_gdpr_lawful_basis_required_failing if {
	some _ in deny with input as {"controls": {}, "gdpr": {"lawful_basis_documented": true}, "controls[\"legaltech": {"gdpr_lawful_basis_required\"]": false}}
}
