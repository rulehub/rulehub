package rulehub.fintech.pan_masking_in_logs

default allow := false

allow if {
	count(deny) == 0
}

deny contains msg if {
	regex.match("^[0-9]{13,19}$", input.logs.line)
	msg := "fintech.pan_masking_in_logs: PAN exposed in logs"
}
