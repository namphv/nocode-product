locals {
  remote_registry_url = "${var.address}/${var.project_id}/${var.client}:${var.current_version}"
}

resource "google_cloud_run_service" "default" {
  name     = var.client
  location = var.location
  project =  var.project_id

  template {
    spec {
      container_concurrency = 80
      containers {
        image = local.remote_registry_url
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1000"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }
  autogenerate_revision_name = true

  depends_on = [
    google_sql_database_instance.instance,
    docker_registry_image.default
  ]
}

resource "google_sql_database_instance" "instance" {
  name             = var.client
  region           = var.location
  database_version = "MYSQL_5_7"
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection  = "true"
}


resource google_cloud_run_domain_mapping default {

  location = google_cloud_run_service.default.location
  project = google_cloud_run_service.default.project
  name = var.domain

  spec {
    route_name = google_cloud_run_service.default.name
  }

  resource_records  {
    type = "CNAME"
    rrdatas = ["${var.client}.${var.domain}."]
    name = var.client
  }
}