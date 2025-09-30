package rulehub.legaltech.aba_model_rule_1_6_confidentiality

default allow := false

allow if count(deny) == 0

deny contains msg if {
	input.matter.safeguards_enabled == false
	msg := "legaltech.aba_model_rule_1_6_confidentiality: Confidentiality safeguards disabled"
}
