package rulehub.medtech.uk_dtac_compliance

test_allow_when_compliant if {
	allow with input as {"controls": {"medtech.uk_dtac_compliance": true}, "nhs": {"clinical_safety": {"dcb0129": true, "dcb0160": true}, "dptk_completed": true}}
}

test_denies_when_nhs_clinical_safety_dcb0129_false if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_dtac_compliance": true}, "nhs": {"clinical_safety": {"dcb0129": false, "dcb0160": true}, "dptk_completed": true}}
}

test_denies_when_nhs_clinical_safety_dcb0160_false if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_dtac_compliance": true}, "nhs": {"clinical_safety": {"dcb0129": true, "dcb0160": false}, "dptk_completed": true}}
}

test_denies_when_nhs_dptk_completed_false if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_dtac_compliance": true}, "nhs": {"clinical_safety": {"dcb0129": true, "dcb0160": true}, "dptk_completed": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_dtac_compliance": false}, "nhs": {"clinical_safety": {"dcb0129": true, "dcb0160": true}, "dptk_completed": true}}
}

# Edge case: All NHS conditions false
test_denies_when_all_nhs_false if {
	count(deny) > 0 with input as {"controls": {"medtech.uk_dtac_compliance": true}, "nhs": {"clinical_safety": {"dcb0129": false, "dcb0160": false}, "dptk_completed": false}}
}
