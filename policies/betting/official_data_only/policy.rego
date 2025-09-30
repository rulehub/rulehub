package rulehub.betting.official_data_only

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.data.source != "official"
	msg := "betting.official_data_only: Non-official data used"
}

deny contains msg if {
	c := input.controls["betting.official_data_only"]
	c == false
	msg := "betting.official_data_only: Generic control failed"
}
