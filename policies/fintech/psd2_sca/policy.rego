package rulehub.fintech.psd2_sca

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.customer.country == "EU"
	input.auth.sca_performed == false
	msg := "PSD2 SCA: strong customer authentication not performed for EU customer"
}
