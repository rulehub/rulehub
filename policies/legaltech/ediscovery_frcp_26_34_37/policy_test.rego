package rulehub.legaltech.ediscovery_frcp_26_34_37

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.ediscovery_frcp_26_34_37": true}, "ediscovery": {"discovery_compliant": true}}
}

test_denies_when_ediscovery_discovery_compliant_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.ediscovery_frcp_26_34_37": true}, "ediscovery": {"discovery_compliant": false}}
}
