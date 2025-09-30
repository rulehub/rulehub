package rulehub.betting.txn_monitoring_anomalies

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.aml.txn_monitoring_enabled == false
	msg := "betting.txn_monitoring_anomalies: Transaction monitoring disabled"
}

deny contains msg if {
	c := input.controls["betting.txn_monitoring_anomalies"]
	c == false
	msg := "betting.txn_monitoring_anomalies: Generic control failed"
}
