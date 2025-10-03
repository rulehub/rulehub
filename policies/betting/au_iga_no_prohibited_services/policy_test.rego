package rulehub.betting.au_iga_no_prohibited_services

# curated: align with policy input.au.offer_prohibited_service
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.au_iga_no_prohibited_services": true}, "au": {"offer_prohibited_service": false}}
}

test_denies_when_prohibited_service_offered if {
	count(deny) > 0 with input as {"controls": {"betting.au_iga_no_prohibited_services": true}, "au": {"offer_prohibited_service": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.au_iga_no_prohibited_services": false}, "au": {"offer_prohibited_service": false}}
}

# Additional deny-focused test: offering prohibited service
test_denies_when_prohibited_service_offered_extra if {
	count(deny) > 0 with input as {"controls": {"betting.au_iga_no_prohibited_services": true}, "au": {"offer_prohibited_service": true}}
}

# Auto-generated granular test for controls["betting.au_iga_no_prohibited_services"]
test_denies_when_controls_betting_au_iga_no_prohibited_services_failing if {
	some _ in deny with input as {"controls": {}, "au": {"offer_prohibited_service": true}, "controls[\"betting": {"au_iga_no_prohibited_services\"]": false}}
}
