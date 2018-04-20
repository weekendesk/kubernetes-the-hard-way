variable "suffix" {
  default = "mbenabda.k8s-1.9-the-hard-way"
}

variable "ami" {
  default = "ami-70054309"
}

variable "admin_user" {
  default = "ubuntu"
}

variable "admin_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDsB266cT0TLrQrHFbSO1EazrcD05P1XxoKAcsML3wLpu3YQjoMswNgZ0nPEZTZFxKAbQx11035jDx3v5ZmdlaNQ0w8JPO9gZYaKdqOb73YZfmLBQnroyB2wMT7D3Y3A2EiwW0ZpKB4zEWEK2L+XvNG0rRlfAzWFhKx2qHWgL2++tNJyVAEwh5K8X83H2ZuQuUj9by0kaeBCA1yiNA8RtaTn3oGgbNMK2jh/2+2lLK7gfIC690L4m7YOCAVPfzUUc0JSCSbhpvkYFny38J8wJFRC6/QGJCDNONoMc4leEAQ3ZfHGYj17LJUHvqx00z5A7dyj6uASW8pgKZajcHn3nmiVS0qHGlaNpWOXN2c9QiTN88YsdWuG4rUALL0dkjiPSfIfdCEi/3YwngmtxkNsyz1VkkXNyQv3IFu3q4QoSiatEI8W2Y6axzxU8SWXXVp2lePXwcv4KsS2WV0sLBYgsmi1NoXZ+kYhccoOPJO1vw4B1M3hoMAWHRbdEYdQER34yq7H8GMRXiNu2oWRs6t6onVFtoj815YsCA23NVc/1pI/w/uCFuSTbXXppOnevWxAqKEs4325GP4AiKz6kTT8vnaptxG17AZc/6l/HhqP104tVTjf8k8kYhxxobk+xMj31RVUZdmOAJP2WM9QXRf4kj9uhz+YJxbl0cfiFY1nd8sw== kthw-mbenabda@weekendesk.com"
}

variable "admin_private_key_file" {
  default = "/home/mbenabda/.ssh/kthw-mbenabda"
}

variable "wed_offices_cidrs" {
  type    = "list"
  default = ["195.68.50.34/32"]
}
