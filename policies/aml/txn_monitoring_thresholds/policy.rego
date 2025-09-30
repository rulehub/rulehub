package rulehub.aml.txn_monitoring_thresholds

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.controls["aml.txn_monitoring_thresholds"] == false
	msg := "aml.txn_monitoring_thresholds: transaction monitoring thresholds not configured"
}
