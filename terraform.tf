project_id          = "cf-ciso-common-sandbo-nh"
region              = "europe-west1"
zone                = "europe-west1-b"

instance_group_name = "instance-group-1"

service_port        = 80
health_check_path   = "/"
lb_name_prefix      = "app"

# Leave empty for HTTP-only. If you want HTTPS, set domain and point DNS to lb_global_ip after apply.
domain = ""
