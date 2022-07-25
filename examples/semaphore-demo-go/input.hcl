pipeline "Semaphore Go CI example" {
  block "Build project" {
    job "go get & build" {
      commands = [
          # Download code from Git repository. This step is mandatory if the
          # job is to work with your code.
        "checkout",

        # Set version of Go:
        "sem-version go 1.16",
        "go get",
        "go build -o ./bin/main",

          # Store the binary in cache to reuse in further blocks.
          # More about caching: https://docs.semaphoreci.com/article/54-toolbox-reference#cache
        "cache store $(checksum main.go) bin"
      ]
    }
  }

  block "Check code style" {
    job "gofmt" {
      commands = [
          # Each job on Semaphore starts from a clean environment, so we
          # repeat the required project setup.
        "checkout",
        "sem-version go 1.16",
        "gofmt main.go | diff --ignore-tab-expansion main.go -"
        ]
    }
  }

  block "Run tests" {
      # This block runs two jobs in parallel and they both share common
      # setup steps. We can group them in a prologue.
      # See https://docs.semaphoreci.com/article/50-pipeline-yaml#prologue
    prologue {
      commands = [
        "checkout",
        "sem-version 1.16"
      ]
    }

    job "go test" {
      commands = [
        # Start Postgres database service.
        # See https://docs.semaphoreci.com/ci-cd-environment/sem-service-managing-databases-and-services-on-linux/
        "sem-service start postgres",
        "psql -p 5432 -h localhost -U postgres -c \"CREATE DATABASE s2\""
        "go get gotest.tools/gotestsum"
        "gotestsum --junitfile junit.xml ./..."
      ]
    }

    job "Test web server" {
      commands = [
        # Restore compiled binary which we created in the first block:
        "cache restore $(checksum main.go)"
        "./bin/main 8001 &"
        "curl --silent localhost:8001/time | grep \"The current time is\""
      ]
    }

    epilogue {
      always {
        commands = [
          "test-results publish junit.xml"
        ]
      }
    }
  }

  after_pipeline {
    job "Publish Results" {
      commands = [
        "test-results gen-pipeline-report"
      ]
    }
  }
}
