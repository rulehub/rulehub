package rulehub.medtech.onc_information_blocking_prohibited

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.onc.information_blocking_detected == true
	msg := "medtech.onc_information_blocking_prohibited: Do not engage in information blocking; support exceptions framework"
}

deny contains msg if {
	input.controls["medtech.onc_information_blocking_prohibited"] == false
	msg := "medtech.onc_information_blocking_prohibited: Generic control failed"
}
