## Parameters

* setup_ns.sh -p peer_name:peer_ip
* ~~setup_fs.sh~~
* **setup_systems.sh**
* **setup_deploy.sh**
* setup_monitor.sh [-b bucket_name]
* ~~setup_log.sh~~
* ~~setup_backup.sh~~
* setup_db.sh -m master_name:master_ip -i server_id -o offset [-b bucket_name]
* setup_mdb.sh -p peer_name:peer_ip[,peer_name:peer_ip,...] [-b bucket_name]
* ~~setup_rfs.sh~~
* setup_sip.sh -p peer_name:peer_ip[,peer_name:peer_ip,...]
* setup_stats.sh -i server_id -o offset [-b bucket_name]
* setup_web.sh [-b bucket_name]
* setup_worker.sh -i server_id -o offset [-b bucket_name]
* setup_jp.sh [-b bucket_name]
* setup_pub.sh -p peer_name:peer_ip -i server_id -o offset [-b bucket_name]
* **setup_eh.sh**
* setup_mq.sh -p peer_name:peer_ip [-b bucket_name]
* **setup_inbound.sh**
* **setup_socket.sh**

## Databases

| host  | peer (-p) | server_id (-i) | offset (-o) |
| ----- | --------- | -------------- | ----------- |
| dbx_0 | dbx_1     | 1              | 1           |
| dbx_1 | dbx_0     | 2              | 2           |
| dbx_2 | dbx_1     | 3              | 1           |

## User Data

```bash
#!/bin/bash
scripts="https://raw.githubusercontent.com/iVirus/gentoo_bootstrap_java/master/templates/hvm/scripts"

filename="/setup_%TYPE%.sh"
echo "--- ${filename} (replace)"
setup_file="$(mktemp)"
curl -sf -o "${setup_file}" "${scripts}${filename}" || exit 1
bash "${setup_file}" %PARAMETERS%
rm "${setup_file}"

rm "${BASH_SOURCE[0]}"
```
