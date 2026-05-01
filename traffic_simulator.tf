resource "kubernetes_namespace" "traffic_sim" {
  metadata {
    name = "traffic-sim"
  }

  depends_on = [local_file.kubeconfig]
}

# Target service: nginx that receives simulated traffic
resource "kubernetes_deployment" "target_nginx" {
  metadata {
    name      = "target-nginx"
    namespace = kubernetes_namespace.traffic_sim.metadata[0].name
    labels = {
      app = "target-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "target-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "target-nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "target_nginx" {
  metadata {
    name      = "target-nginx"
    namespace = kubernetes_namespace.traffic_sim.metadata[0].name
  }

  spec {
    selector = {
      app = "target-nginx"
    }

    port {
      port        = 80
      target_port = 80
    }
  }
}

# Traffic generator: sends continuous HTTP requests to the target service
resource "kubernetes_deployment" "traffic_generator" {
  metadata {
    name      = "traffic-generator"
    namespace = kubernetes_namespace.traffic_sim.metadata[0].name
    labels = {
      app = "traffic-generator"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traffic-generator"
      }
    }

    template {
      metadata {
        labels = {
          app = "traffic-generator"
        }
      }

      spec {
        container {
          name  = "generator"
          image = "curlimages/curl:latest"

          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            TARGET="http://target-nginx.traffic-sim.svc.cluster.local"
            echo "Traffic generator started. Target: $TARGET"
            COUNTER=0
            while true; do
              COUNTER=$((COUNTER + 1))
              MOD=$((COUNTER % 20))

              if [ $MOD -lt 16 ]; then
                curl -s -o /dev/null -w "GET / -> %%{http_code} (%%{time_total}s)\n" "$TARGET/"
              elif [ $MOD -lt 19 ]; then
                curl -s -o /dev/null -w "GET /slow -> %%{http_code} (%%{time_total}s)\n" --max-time 5 "$TARGET/slow-endpoint"
              else
                curl -s -o /dev/null -w "GET /missing -> %%{http_code} (%%{time_total}s)\n" "$TARGET/this-does-not-exist"
              fi

              # Random sleep between 0.1s and 1s to vary request rate
              SLEEP_MS=$(( (RANDOM % 10 + 1) ))
              sleep "0.$SLEEP_MS"
            done
          EOT
          ]

          resources {
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.target_nginx]
}
