package rulehub.gdpr.consent_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["gdpr.consent_required"] == false
	msg := "gdpr.consent_required: valid consent not present"
}
