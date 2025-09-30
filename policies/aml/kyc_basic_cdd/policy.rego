package rulehub.aml.kyc_basic_cdd

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.kyc_basic_cdd"] == false
	msg := "aml.kyc_basic_cdd: basic customer due diligence not completed"
}
