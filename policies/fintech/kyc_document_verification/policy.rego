package rulehub.fintech.kyc_document_verification

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.kyc.docs_verified == false
	input.kyc.document_verified == false
	msg := "fintech.kyc_document_verification: Document verification failed/missing"
}
