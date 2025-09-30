package rulehub.k8s.no_privileged

default allow := false

allow if count(deny) == 0

deny contains msg if {
	some container in all_containers
	container.securityContext.privileged == true
	msg := sprintf("k8s.no_privileged: container %q is privileged", [container.name])
}

# Deny if Pod-level securityContext sets privileged (edge cases / malformed specs).
deny contains msg if {
	input.kind == "Pod"
	input.spec.securityContext.privileged == true
	msg := "k8s.no_privileged: pod securityContext privileged"
}

# Fallback control flag (legacy/simple control toggle) if provided and false.
deny contains msg if {
	input.controls["k8s.no_privileged"] == false
	not has_privileged_containers # Avoid duplicate messages if containers already flagged
	msg := "k8s.no_privileged: control disabled (no_privileged not enforced)"
}

has_privileged_containers if {
	some c in all_containers
	c.securityContext.privileged == true
}

all_containers contains c if {
	input.kind == "Pod"
	input.spec.containers[_] = c
}

all_containers contains c if {
	input.kind == "Pod"
	input.spec.initContainers[_] = c
}

all_containers contains c if {
	input.kind == "Pod"
	input.spec.ephemeralContainers[_] = c
}
