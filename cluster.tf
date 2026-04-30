terraform {
  required_version = ">= 1.5"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

resource "linode_lke_cluster" "cluster" {
  label       = "cluster"
  k8s_version = "1.35"
  region      = "ap-northeast"
  tags        = ["prod"]

  pool {
    type  = "g6-standard-2"
    count = 1
  }
}

resource "local_file" "kubeconfig" {
  content         = base64decode(linode_lke_cluster.cluster.kubeconfig)
  filename        = "${path.module}/kubeconfig.yaml"
  file_permission = "0600"
}
