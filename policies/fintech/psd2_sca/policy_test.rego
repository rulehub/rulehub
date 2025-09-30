package rulehub.fintech.psd2_sca

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.psd2_sca": true}, "auth": {"sca_performed": true}, "customer": {"country": "EU"}}
}

test_denies_when_auth_sca_performed_false if {
	count(deny) > 0 with input as {"controls": {"fintech.psd2_sca": true}, "auth": {"sca_performed": false}, "customer": {"country": "EU"}}
}
