packer {
  required_plugins {
    docker = {
      source = "github.com/hashicorp/docker"
      version = ">= 1.0.0"
    }
  }
}

source "docker" "example" {
  image = "ubuntu:24.04"
  export_path = "output/virtual-image.tar"
}

build {
  sources = ["source.docker.example"]
}
