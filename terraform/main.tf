terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "CH_PASSWORD" {}

provider "yandex" {
  zone                     = "ru-central1-a"
  service_account_key_file = "../.yc_svc_key.json"
}

resource "yandex_mdb_clickhouse_cluster" "ch_dmda" {
  name                    = "ch_dmda"
  environment             = "PRESTABLE"
  network_id              = yandex_vpc_network.dmda_network.id
  sql_database_management = true
  sql_user_management     = true
  admin_password          = var.CH_PASSWORD
  version                 = "23.3"

  clickhouse {
    resources {
      resource_preset_id = "s3-c4-m16"
      disk_type_id       = "network-ssd"
      disk_size          = 64
    }

    config {
      log_level                       = "TRACE"
      max_connections                 = 100
      max_concurrent_queries          = 100
      keep_alive_timeout              = 3000
      uncompressed_cache_size         = 8589934592
      mark_cache_size                 = 5368709120
      max_table_size_to_drop          = 53687091200
      max_partition_size_to_drop      = 53687091200
      timezone                        = "UTC"
      geobase_uri                     = ""
      query_log_retention_size        = 1073741824
      query_log_retention_time        = 86400000
      query_thread_log_enabled        = true
      query_thread_log_retention_size = 536870912
      query_thread_log_retention_time = 86400000
      part_log_retention_size         = 536870912
      part_log_retention_time         = 86400000
      metric_log_enabled              = true
      metric_log_retention_size       = 536870912
      metric_log_retention_time       = 86400000
      trace_log_enabled               = true
      trace_log_retention_size        = 536870912
      trace_log_retention_time        = 86400000
      text_log_enabled                = true
      text_log_retention_size         = 536870912
      text_log_retention_time         = 86400000
      text_log_level                  = "TRACE"
      background_pool_size            = 16
      background_schedule_pool_size   = 16

      merge_tree {
        replicated_deduplication_window                           = 100
        replicated_deduplication_window_seconds                   = 604800
        parts_to_delay_insert                                     = 150
        parts_to_throw_insert                                     = 300
        max_replicated_merges_in_queue                            = 16
        number_of_free_entries_in_pool_to_lower_max_size_of_merge = 8
        max_bytes_to_merge_at_min_space_in_pool                   = 1048576
      }

      kafka {
        security_protocol = "SECURITY_PROTOCOL_PLAINTEXT"
        sasl_mechanism    = "SASL_MECHANISM_GSSAPI"
        sasl_username     = "user_1"
        sasl_password     = "pass_1"
      }

      kafka_topic {
        name = "topic1"
        settings {
          security_protocol = "SECURITY_PROTOCOL_SSL"
          sasl_mechanism    = "SASL_MECHANISM_SCRAM_SHA_256"
          sasl_username     = "user_2"
          sasl_password     = "pass_2"
        }
      }

      kafka_topic {
        name = "topic2"
        settings {
          security_protocol = "SECURITY_PROTOCOL_SASL_PLAINTEXT"
          sasl_mechanism    = "SASL_MECHANISM_PLAIN"
        }
      }

      rabbitmq {
        username = "rabbit_user"
        password = "rabbit_pass"
      }

      compression {
        method              = "LZ4"
        min_part_size       = 1024
        min_part_size_ratio = 0.5
      }

      compression {
        method              = "ZSTD"
        min_part_size       = 2048
        min_part_size_ratio = 0.7
      }

      graphite_rollup {
        name = "rollup1"
        pattern {
          regexp   = "abc"
          function = "func1"
          retention {
            age       = 1000
            precision = 3
          }
        }
      }

      graphite_rollup {
        name = "rollup2"
        pattern {
          function = "func2"
          retention {
            age       = 2000
            precision = 5
          }
        }
      }
    }
  }

  host {
    type             = "CLICKHOUSE"
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.dmda_subnet.id
    assign_public_ip = true
  }

  cloud_storage {
    enabled = false
  }

  maintenance_window {
    type = "ANYTIME"
  }
}

resource "yandex_vpc_network" "dmda_network" {}

resource "yandex_vpc_subnet" "dmda_subnet" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.dmda_network.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

resource "yandex_compute_instance" "airbyte" {
  name        = "airbyte"
  platform_id = "standard-v3"
  zone        = yandex_vpc_subnet.dmda_subnet.zone

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 100
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image_id = "fd8linvus5t2ielkr8no" # with Airbyte installed
      # image_id = "fd80o2eikcn22b229tsa" # Container-optimized image
      size = 30
      type = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.dmda_subnet.id
    ipv4      = true
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = {
    user-data = "${file("airbyte_meta.yaml")}"
  }
}