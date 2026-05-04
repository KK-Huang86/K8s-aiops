resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 600
  wait             = false

  set {
    name  = "controller.allowSnippetAnnotations"
    value = "true"
  }

  set {
    name  = "controller.config.allow-snippet-annotations"
    value = "true"
  }

  set {
    name  = "controller.config.annotations-risk-level"
    value = "Critical"
  }

  depends_on = [local_file.kubeconfig]
}

# 取得 ingress controller 的 LoadBalancer IP
data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}

locals {
  nginx_ip  = try(data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].ip, "pending")
  keep_host = "${local.nginx_ip}.nip.io"
}
