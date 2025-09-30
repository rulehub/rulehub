package rulehub.fintech.aml_duplicate_account_detection

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.customer.duplicate_detected
	msg := "fintech.aml_duplicate_account_detection: Duplicate account detected"
}
