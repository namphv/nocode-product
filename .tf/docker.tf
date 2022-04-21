resource "docker_registry_image" "default" {
  name = local.remote_registry_url

  build {
    context = "./.docker"
    auth_config = {

    }
  }
}
