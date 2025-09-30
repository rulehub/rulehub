package rulehub.fintech.aml_watchlist_management

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["fintech.aml_watchlist_management"] == false
	msg := "fintech.aml_watchlist_management: Generic fintech control failed"
}
