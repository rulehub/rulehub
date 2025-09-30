package rulehub.fintech.kyc_source_of_wealth

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.kyc.sow_collected == false
	msg := "fintech.kyc_source_of_wealth: Source of wealth not collected"
}
