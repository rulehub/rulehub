package rulehub.legaltech.cpra_sensitive_data_limited_use

test_allow_when_compliant if {
	allow with input as {"controls": {"legaltech.cpra_sensitive_data_limited_use": true}, "ccpa": {"spi_limited_use": true}}
}

test_denies_when_ccpa_spi_limited_use_false if {
	count(deny) > 0 with input as {"controls": {"legaltech.cpra_sensitive_data_limited_use": true}, "ccpa": {"spi_limited_use": false}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"legaltech.cpra_sensitive_data_limited_use": false}, "ccpa": {"spi_limited_use": true}}
}

# Edge case: control disabled and SPI limited use not enforced
test_denies_when_control_disabled_and_spi_not_limited if {
	count(deny) > 0 with input as {"controls": {"legaltech.cpra_sensitive_data_limited_use": true}, "ccpa": {"spi_limited_use": false}}
}
