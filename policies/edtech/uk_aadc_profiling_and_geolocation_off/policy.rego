package rulehub.edtech.uk_aadc_profiling_and_geolocation_off

default allow := false

# Safe allow pattern for Rego v1
allow if {
	count(deny) == 0
}

# Example deny; replace with real checks
deny contains msg if {
	input.aadc.profiling_enabled == true
	msg := "edtech.uk_aadc_profiling_and_geolocation_off: Profiling enabled by default"
}

deny contains msg if {
	input.aadc.geolocation_enabled == true
	msg := "edtech.uk_aadc_profiling_and_geolocation_off: Geolocation enabled by default"
}

deny contains msg if {
	input.controls["edtech.uk_aadc_profiling_and_geolocation_off"] == false
	msg := "edtech.uk_aadc_profiling_and_geolocation_off: Generic control failed"
}
