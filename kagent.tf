resource "kubernetes_namespace_v1" "kagent" {
  metadata {
    name = "kagent"
  }
}

resource "helm_release" "kagent_crds" {
  name       = "kagent-crds"
  repository = "oci://ghcr.io/kagent-dev/kagent/helm"
  chart      = "kagent-crds"
  namespace  = kubernetes_namespace_v1.kagent.metadata[0].name

  depends_on = [kubernetes_namespace_v1.kagent]
}

resource "helm_release" "kagent" {
  name       = "kagent"
  repository = "oci://ghcr.io/kagent-dev/kagent/helm"
  chart      = "kagent"
  namespace  = kubernetes_namespace_v1.kagent.metadata[0].name

  values = [
    yamlencode({
      providers = {
        default = "gemini"
        gemini = {
          apiKey = var.gemini_api_key
          model  = "gemini-2.5-flash-lite"
        }
      }
    })
  ]

  depends_on = [helm_release.kagent_crds]
}
