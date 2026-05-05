resource "kubernetes_namespace" "traffic_sim" {
  metadata {
    name = "traffic-sim"
  }

  depends_on = [local_file.kubeconfig]
}

resource "kubernetes_job" "cpu_stress" {
  metadata {
    name      = "cpu-stress"
    namespace = kubernetes_namespace.traffic_sim.metadata[0].name
  }

  wait_for_completion = false

  spec {
    completions = 1
    parallelism = 2

    template {
      metadata {
        labels = {
          app = "cpu-stress"
        }
      }

      spec {
        restart_policy = "Never"

        container {
          name    = "stress"
          image   = "polinux/stress"
          command = ["stress"]
          args    = ["--cpu", "2", "--timeout", "600", "--verbose"]

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
