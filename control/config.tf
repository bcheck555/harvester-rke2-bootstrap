resource "kubernetes_secret" "cp_main_config" {
  metadata {
    name = "${var.node_name_prefix}-cp-config"
  }

  type = "secret"

  data = {
    userdata = <<EOT
      #cloud-config
      rh_subscription:
        activation-key: ###ADD YOUR KEY
        org: ###ADD YOUR ORG
        auto-attach: True
        service-level: self-support
      users:
        - name: root
          lock_passwd: false
          plain_text_passwd: 'password' ###FOR TESTING
        - name: admin
          lock_passwd: false
          plain_text_passwd: 'password' ###FOR TESTING
          shell: /bin/bash
          groups: wheel
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh-authorized-keys:
          - ${var.ssh_pubkey}
      ssh_pwauth: True ## This line enables ssh password authentication
      write_files:
      - path: /etc/rancher/rke2/config.yaml
        owner: root
        content: |
          token: ${var.cluster_token}
          tls-san:
            - ${var.node_name_prefix}-0
            - ${var.master_hostname}
            - ${var.master_vip}
          profile: cis-1.23
          selinux: true
          secrets-encryption: true
          write-kubeconfig-mode: 0640
          use-service-account-credentials: true
          kube-controller-manager-arg:
          - bind-address=127.0.0.1
          - use-service-account-credentials=true
          - tls-min-version=VersionTLS12
          - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          kube-scheduler-arg:
          - tls-min-version=VersionTLS12
          - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          kube-apiserver-arg:
          - tls-min-version=VersionTLS12
          - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          - authorization-mode=RBAC,Node
          - anonymous-auth=false
          - audit-policy-file=/etc/rancher/rke2/audit-policy.yaml
          - audit-log-mode=blocking-strict
          - audit-log-maxage=30
          kubelet-arg:
          - protect-kernel-defaults=true
          - read-only-port=0
          - authorization-mode=Webhook
          - streaming-connection-idle-timeout=5m
      - path: /etc/hosts
        owner: root
        content: |
          127.0.0.1 localhost
          127.0.0.1 ${var.node_name_prefix}-0
          127.0.0.1 ${var.master_hostname}
      - path: /etc/sysctl.d/60-rke2.conf
        content: |
          # Kernel Tuning for RKE2
          vm.swappiness=0
          vm.panic_on_oom=0
          vm.overcommit_memory=1
          kernel.panic=10
          kernel.panic_on_oops=1
          vm.max_map_count = 262144
          net.ipv4.ip_local_port_range=1024 65000
          Increase max connection
          net.core.somaxconn=10000
          net.ipv4.tcp_tw_reuse=1
          net.ipv4.tcp_fin_timeout=15
          net.core.somaxconn=4096
          net.core.netdev_max_backlog=4096
          net.core.rmem_max=16777216
          net.core.wmem_max=16777216
          net.ipv4.tcp_max_syn_backlog=20480
          net.ipv4.tcp_max_tw_buckets=400000
          net.ipv4.tcp_no_metrics_save=1
          net.ipv4.tcp_rmem=4096 87380 16777216
          net.ipv4.tcp_syn_retries=2
          net.ipv4.tcp_synack_retries=2
          net.ipv4.tcp_wmem=4096 65536 16777216
          net.ipv4.tcp_keepalive_time=600
          net.ipv4.ip_forward=1
          net.ipv6.ip_forward=1
          fs.inotify.max_user_instances=8192
          fs.inotify.max_user_watches=1048576
      runcmd:
      - - systemctl
        - enable
        - '--now'
        - qemu-guest-agent.service
      - curl -sfL https://get.rke2.io -o ~/install.sh
      - INSTALL_RKE2_VERSION=${var.rke2_version} sh ~/install.sh
      - export RKE2_VIP_IP=${var.master_vip}
      - export RKE2_VIP_INTERFACE=${var.master_vip_interface}
      - mkdir -p /var/lib/rancher/rke2/server/manifests
      - curl -sfL https://kube-vip.io/manifests/rbac.yaml -o /var/lib/rancher/rke2/server/manifests/kube-vip-rbac.yaml
      - curl -sL kube-vip.io/k3s |  vipAddress=${var.master_vip} vipInterface=${var.master_vip_interface} sh | sudo tee /var/lib/rancher/rke2/server/manifests/vip.yaml
      - systemctl enable rke2-server.service
      - useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
      - systemctl restart systemd-sysctl
      - systemctl start rke2-server.service
      - echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' >> ~/.bashrc ; echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc ; echo 'alias k=kubectl' >> ~/.bashrc
      ssh_authorized_keys: 
      - ${var.ssh_pubkey}
    EOT 
  }
}

resource "kubernetes_secret" "cp_ha_config" {
  count = var.ha_mode == true ? 2 : 0
  metadata {
    name = "${var.node_name_prefix}-cp-ha-config-${count.index + 1}"
  }

  type = "secret"

  data = {
    userdata = <<EOT
      #cloud-config
      rh_subscription:
        activation-key: ###ADD YOUR KEY
        org: ###ADD YOUR ORG
        auto-attach: True
        service-level: self-support
      users:
        - name: root
          lock_passwd: false
          plain_text_passwd: 'password' ###FOR TESTING
        - name: admin
          lock_passwd: false
          plain_text_passwd: 'password' ###FOR TESTING
          shell: /bin/bash
          groups: wheel
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh-authorized-keys:
          - ${var.ssh_pubkey}
      ssh_pwauth: True ## This line enables ssh password authentication
      package_update: true
      write_files:
      - path: /etc/rancher/rke2/config.yaml
        owner: root
        content: |
          token: ${var.cluster_token}
          server: https://${var.master_hostname}:9345
          tls-san:
            - ${var.node_name_prefix}-${count.index + 1}
            - ${var.master_hostname}
            - ${var.master_vip}
          profile: cis-1.23
          selinux: true
          secrets-encryption: true
          write-kubeconfig-mode: 0640
          use-service-account-credentials: true
          kube-controller-manager-arg:
          - bind-address=127.0.0.1
          - use-service-account-credentials=true
          - tls-min-version=VersionTLS12
          - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          kube-scheduler-arg:
          - tls-min-version=VersionTLS12
          - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          kube-apiserver-arg:
          - tls-min-version=VersionTLS12
          - tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          - authorization-mode=RBAC,Node
          - anonymous-auth=false
          - audit-policy-file=/etc/rancher/rke2/audit-policy.yaml
          - audit-log-mode=blocking-strict
          - audit-log-maxage=30
          kubelet-arg:
          - protect-kernel-defaults=true
          - read-only-port=0
          - authorization-mode=Webhook
          - streaming-connection-idle-timeout=5m
      - path: /etc/hosts
        owner: root
        content: |
          127.0.0.1 localhost
          127.0.0.1 ${var.node_name_prefix}-${count.index + 1}
          ${var.master_vip} ${var.master_hostname}
      - path: /etc/sysctl.d/60-rke2.conf
        content: |
          # Kernel Tuning for RKE2
          vm.swappiness=0
          vm.panic_on_oom=0
          vm.overcommit_memory=1
          kernel.panic=10
          kernel.panic_on_oops=1
          vm.max_map_count = 262144
          net.ipv4.ip_local_port_range=1024 65000
          Increase max connection
          net.core.somaxconn=10000
          net.ipv4.tcp_tw_reuse=1
          net.ipv4.tcp_fin_timeout=15
          net.core.somaxconn=4096
          net.core.netdev_max_backlog=4096
          net.core.rmem_max=16777216
          net.core.wmem_max=16777216
          net.ipv4.tcp_max_syn_backlog=20480
          net.ipv4.tcp_max_tw_buckets=400000
          net.ipv4.tcp_no_metrics_save=1
          net.ipv4.tcp_rmem=4096 87380 16777216
          net.ipv4.tcp_syn_retries=2
          net.ipv4.tcp_synack_retries=2
          net.ipv4.tcp_wmem=4096 65536 16777216
          net.ipv4.tcp_keepalive_time=600
          net.ipv4.ip_forward=1
          net.ipv6.ip_forward=1
          fs.inotify.max_user_instances=8192
          fs.inotify.max_user_watches=1048576
      runcmd:
      - - systemctl
        - enable
        - '--now'
        - qemu-guest-agent.service
      - curl -sfL https://get.rke2.io -o ~/install.sh
      - INSTALL_RKE2_VERSION=${var.rke2_version} sh ~/install.sh
      - systemctl enable rke2-server.service
      - useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
      - systemctl restart systemd-sysctl
      - systemctl start rke2-server.service
      ssh_authorized_keys: 
      - ${var.ssh_pubkey}
    EOT 
  }
}