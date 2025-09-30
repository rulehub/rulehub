package rulehub.edtech.uk_aadc_privacy_by_default

test_allow_when_compliant if {
	allow with input as {"controls": {"edtech.uk_aadc_privacy_by_default": true}, "aadc": {"privacy_by_default": true}}
}

test_denies_when_aadc_privacy_by_default_false if {
	count(deny) > 0 with input as {"controls": {"edtech.uk_aadc_privacy_by_default": true}, "aadc": {"privacy_by_default": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.uk_aadc_privacy_by_default": false}, "aadc": {"privacy_by_default": true}}
}

test_denies_when_privacy_by_default_disabled_and_control_disabled if {
	count(deny) > 0 with input as {"controls": {"edtech.uk_aadc_privacy_by_default": false}, "aadc": {"privacy_by_default": false}}
}
