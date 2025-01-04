resource "kubernetes_namespace" "example" {
  metadata {
    name = var.pralay
  }
}

resource "helm_release" "nginx" {
  name       = "nginx1"
  namespace  = var.pralay # Ensure the namespace "data2" exists
  chart      = "../kumar" # Adjust the chart path if necessary

  values = [
    yamlencode({
      replicaCount = var.replicaCount
    })
  ]
  depends_on = [kubernetes_namespace.example]
}


