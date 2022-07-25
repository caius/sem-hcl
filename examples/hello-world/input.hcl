pipeline "Hello World" {
  version = "v1.0"

  agent {
    machine {
      type = "e1-standard-2"
      os_image = "ubuntu2004"
    }
  }

  block "Hello World Test" {
    task {
      job "Test" {
        commands = [
          "docker run hello-world | grep \"Hello from Docker\""
        ]
      }
    }
  }
}
