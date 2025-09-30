package rulehub.fintech.psd2_transaction_risk_analysis

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.psd2_transaction_risk_analysis"] == false
	input.transaction.sca_passed == false
	msg := "fintech.psd2_transaction_risk_analysis: Generic fintech control failed"
}
