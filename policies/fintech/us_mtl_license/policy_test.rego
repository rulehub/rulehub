package rulehub.fintech.us_mtl_license

test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.us_mtl_license": true}, "mtl_licensed": true, "customer": {"country": "US"}}
}

test_denies_when_mtl_licensed_false if {
	count(deny) > 0 with input as {"controls": {"fintech.us_mtl_license": true}, "mtl_licensed": false, "customer": {"country": "US"}}
}
