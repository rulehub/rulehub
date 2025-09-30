package rulehub.betting.ongoing_aml_monitoring

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.aml.txn_monitoring_enabled == false
	msg := "gambling.ongoing_aml_monitoring: Ongoing monitoring of transactions and behavior"
}

deny contains msg if {
	input.controls["betting.ongoing_aml_monitoring"] == false
	msg := "gambling.ongoing_aml_monitoring: Generic control failed"
}
