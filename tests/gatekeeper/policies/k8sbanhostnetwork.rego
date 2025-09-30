package k8sbanhostnetwork

violation contains {"msg": msg} if {
  input.review.object.kind == "Pod"
  input.review.object.spec.hostNetwork == true
  msg := "hostNetwork is not allowed"
}
