package k8srunasnonroot

violation contains {"msg": msg} if {
  input.review.object.kind == "Pod"
  some i
  c := input.review.object.spec.containers[i]
  not c.securityContext.runAsNonRoot
  msg := "Containers must set securityContext.runAsNonRoot=true"
}
