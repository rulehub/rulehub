package rulehub.fintech.kyc_source_of_funds

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.kyc.sof_collected == false
	msg := "fintech.kyc_source_of_funds: Source of funds not collected"
}
