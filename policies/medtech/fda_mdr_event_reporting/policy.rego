package rulehub.medtech.fda_mdr_event_reporting

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

## Deny only when MDR reporting process explicitly NOT defined
deny contains msg if {
	input.fda.mdr_reporting_process_defined == false
	msg := "medtech.fda_mdr_event_reporting: Report adverse events to FDA within required timelines (MDR)"
}

deny contains msg if {
	input.controls["medtech.fda_mdr_event_reporting"] == false
	msg := "medtech.fda_mdr_event_reporting: Generic control failed"
}
