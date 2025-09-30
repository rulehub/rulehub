package rulehub.fintech.aml_manual_review_queue

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.aml_manual_review_queue"] == false
	msg := "fintech.aml_manual_review_queue: Generic fintech control failed"
}
