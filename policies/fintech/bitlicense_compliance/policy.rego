package rulehub.fintech.bitlicense_compliance

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.crypto.licensing_compliant == false
	msg := "fintech.bitlicense_compliance: Crypto/VASP licensing not compliant"
}
