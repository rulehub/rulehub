package rulehub.gdpr.data_retention

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["gdpr.data_retention"] == false
	msg := "gdpr.data_retention: retention limits not enforced"
}
