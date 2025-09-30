package rulehub.fintech.vasp_license_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.crypto.licensing_compliant == false
	msg := "fintech.vasp_license_required: Crypto/VASP licensing not compliant"
}
