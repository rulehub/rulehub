package k8simagepullalways

violation contains {"msg": msg} if {
  input.review.object.kind == "Pod"
  some i
  c := input.review.object.spec.containers[i]
  c.imagePullPolicy != "Always"
  msg := "imagePullPolicy must be Always"
}
