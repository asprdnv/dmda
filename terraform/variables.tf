output "clickhouse_host_fqdn" {
  value = resource.yandex_mdb_clickhouse_cluster.ch_dmda.host[0].fqdn
}

output "yandex_compute_instance_nat_ip_address" {
  value = yandex_compute_instance.airbyte.network_interface.0.nat_ip_address
}