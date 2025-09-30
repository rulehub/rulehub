package rulehub.fintech.aml_adverse_media_screening

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.adverse_media_screened == false
	msg := "fintech.aml_adverse_media_screening: Adverse media not screened"
}
