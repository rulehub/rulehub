package rulehub.betting.aml_sar_reporting_uk

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.aml.suspicion
	input.aml.sar_filed == false
	msg := "gambling.aml_sar_reporting_uk: File SARs with NCA when suspicion arises"
}

deny contains msg if {
	input.controls["betting.aml_sar_reporting_uk"] == false
	msg := "gambling.aml_sar_reporting_uk: Generic control failed"
}
