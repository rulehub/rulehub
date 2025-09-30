package rulehub.fintech.oauth2_pkce_required

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.oauth2_pkce_required"] == false
	msg := "fintech.oauth2_pkce_required: Generic fintech control failed"
}
