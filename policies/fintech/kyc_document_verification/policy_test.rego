package rulehub.fintech.kyc_document_verification

# curated: atomic failures separated
test_allow_when_compliant if {
	allow with input as {"controls": {"fintech.kyc_document_verification": true}, "kyc": {"docs_verified": true, "document_verified": true}}
}

test_denies_when_kyc_docs_verified_false if {
	count(deny) > 0 with input as {"controls": {"fintech.kyc_document_verification": true}, "kyc": {"docs_verified": false, "document_verified": false}}
}
