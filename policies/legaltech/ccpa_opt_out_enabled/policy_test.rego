package rulehub.legaltech.ccpa_opt_out_enabled

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ccpa_opt_out_enabled": true}, "ccpa": {"opt_out_enabled": true}}
}

test_denies_when_ccpa_opt_out_enabled_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_opt_out_enabled": true}, "ccpa": {"opt_out_enabled": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_opt_out_enabled": false}, "ccpa": {"opt_out_enabled": true}}
}

# Edge case: control disabled and opt-out not enabled
test_denies_when_control_disabled_and_opt_out_missing if {
	count(deny) > 0 with input as {"controls": {"legaltech.ccpa_opt_out_enabled": true}, "ccpa": {"opt_out_enabled": false}}
}
