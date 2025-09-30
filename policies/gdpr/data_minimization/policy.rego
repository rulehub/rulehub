package rulehub.gdpr.data_minimization

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["gdpr.data_minimization"] == false
	msg := "gdpr.data_minimization: data minimization not demonstrated"
}
