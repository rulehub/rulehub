package rulehub.betting.au_iga_no_prohibited_services

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.au.offer_prohibited_service == true
	msg := "gambling.au_iga_no_prohibited_services: Do not offer prohibited interactive gambling services to Australian customers"
}

deny contains msg if {
	input.controls["betting.au_iga_no_prohibited_services"] == false
	msg := "gambling.au_iga_no_prohibited_services: Generic control failed"
}
