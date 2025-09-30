package k8slimitcapabilities

violation contains {"msg": msg} if {
  input.review.object.kind == "Pod"
  some i
  c := input.review.object.spec.containers[i]
  not ("ALL" in c.securityContext.capabilities.drop)
  msg := "Must drop ALL capabilities"
}
