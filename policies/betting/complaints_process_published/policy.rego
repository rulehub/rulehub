package rulehub.betting.complaints_process_published

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.complaints.process_published == false
	msg := "gambling.complaints_process_published: Publish clear complaint handling process and timelines"
}

deny contains msg if {
	input.controls["betting.complaints_process_published"] == false
	msg := "gambling.complaints_process_published: Generic control failed"
}
