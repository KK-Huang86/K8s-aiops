resource "kubectl_manifest" "flash_model_config" {
  yaml_body = <<-YAML
    apiVersion: kagent.dev/v1alpha2
    kind: ModelConfig
    metadata:
      name: flash-model-config
      namespace: kagent
    spec:
      provider: Gemini
      model: gemini-2.5-flash-lite
      apiKeySecret: kagent-gemini
      apiKeySecretKey: GOOGLE_API_KEY
  YAML

  depends_on = [helm_release.kagent]
}
