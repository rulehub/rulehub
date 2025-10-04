package rulehub.betting.reverse_withdrawal_ban_uk

# curated: add withdrawal.reverse_enabled evidence
test_allow_when_compliant if {
	allow with input as {"controls": {"betting.reverse_withdrawal_ban_uk": true}, "withdrawal": {"reverse_enabled": false}}
}

test_denies_when_withdrawal_reverse_enabled_true if {
	count(deny) > 0 with input as {"controls": {"betting.reverse_withdrawal_ban_uk": true}, "withdrawal": {"reverse_enabled": true}}
}

test_denies_when_control_disabled if {
	count(deny) > 0 with input as {"controls": {"betting.reverse_withdrawal_ban_uk": false}, "withdrawal": {"reverse_enabled": false}}
}

test_denies_when_withdrawal_and_control_fail_extra if {
	count(deny) > 0 with input as {"controls": {"betting.reverse_withdrawal_ban_uk": false}, "withdrawal": {"reverse_enabled": true}}
}

# Auto-generated granular test for controls["betting.reverse_withdrawal_ban_uk"]
test_denies_when_controls_betting_reverse_withdrawal_ban_uk_failing if {
	some _ in deny with input as {"controls": {"betting.reverse_withdrawal_ban_uk": false}, "withdrawal": {"reverse_enabled": true}}
}
