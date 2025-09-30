package rulehub.legaltech.ediscovery_frcp_26_34_37

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.ediscovery.discovery_compliant == false
	msg := "legaltech.ediscovery_frcp_26_34_37: FRCP discovery non-compliant"
}
