resource "kubernetes_namespace" "traffic_sim" {
  metadata {
    name = "traffic-sim"
  }

  depends_on = [local_file.kubeconfig]
}

resource "kubernetes_deployment" "cpu_stress" {
  metadata {
    name      = "cpu-stress"
    namespace = kubernetes_namespace.traffic_sim.metadata[0].name
    labels = {
      app = "cpu-stress"
    }
  }

  wait_for_rollout = false

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "cpu-stress"
      }
    }

    template {
      metadata {
        labels = {
          app = "cpu-stress"
        }
      }

      spec {
        container {
          name  = "stress"
          image = "polinux/stress"

          # 每個 Pod 跑 2 個 CPU worker，對應節點的 2 vCPU
          # 跑 10 分鐘後自動停止，足以觸發 alert 又不會無限消耗
          args = ["--cpu", "2", "--timeout", "600", "--verbose"]

          resources {
            requests = {
              cpu    = "200m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "2000m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}
