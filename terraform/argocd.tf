resource "null_resource" "gateway_api_crds" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${local.region} --name ${local.name} && kubectl apply -k github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.0.0"
  }
  depends_on = [module.eks]
}

resource "helm_release" "nginx_gateway_fabric" {
  name             = "nginx-gateway"
  chart            = "oci://ghcr.io/nginx/charts/nginx-gateway-fabric"
  version          = "1.2.0"
  namespace        = "nginx-gateway"
  create_namespace = true

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"
      }
    })
  ]

  depends_on = [null_resource.gateway_api_crds]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = false
        }
      }
    })
  ]

  depends_on = [helm_release.nginx_gateway_fabric]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.14.4"

  values = [
    yamlencode({
      installCRDs = true
      extraArgs = [
        "--feature-gates=ExperimentalGatewayAPISupport=true"
      ]
    })
  ]

  depends_on = [module.eks]
}

resource "null_resource" "cluster_issuer" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${local.region} --name ${local.name} && kubectl apply -f ../gateway/cluster-issuer.yml"
  }
  depends_on = [helm_release.cert_manager]
}