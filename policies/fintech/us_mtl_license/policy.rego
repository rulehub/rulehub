package rulehub.fintech.us_mtl_license

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.customer.country == "US"
	input.mtl_licensed == false
	msg := "US MTL: money transmitter license required for operations in US jurisdictions"
}
