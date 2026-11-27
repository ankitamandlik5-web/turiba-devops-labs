resource "kind_cluster" "course" {
  name           = var.cluster_name
  wait_for_ready = true
}

resource "kubernetes_namespace_v1" "course" {
  metadata {
    name = "course"
  }
}


resource "helm_release" "course_app" {
  name      = "course-app"
  namespace = kubernetes_namespace_v1.course.metadata[0].name
  chart     = "${path.module}/../charts/course-app"

  set = [
    { name = "api.replicas", value = tostring(var.api_replicas) },
  ]

}
