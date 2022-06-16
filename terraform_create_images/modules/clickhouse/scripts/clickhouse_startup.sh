#!/bin/bash

OT_RCFILE=/etc/opentargets.rc

if [ -f "$OT_RCFILE" ]; then
    echo "$OT_RCFILE exist so machine is already configured"
    exit 0
fi

apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get \
    -o Dpkg::Options::="--force-confnew" \
    --force-yes \
    -fuy \
    dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get \
    -o Dpkg::Options::="--force-confnew" \
    --force-yes \
    -fuy \
    install default-jdk openjdk-11-jdk-headless bzip2 unzip zip wget net-tools wget uuid-runtime python-pip python-dev libyaml-dev httpie jq gawk tmux git build-essential less silversearcher-ag dirmngr psmisc

cluster_id=$(uuidgen -r)

cat <<EOF > /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
* soft memlock unlimited
* hard memlock unlimited

EOF

cat <<EOF > /etc/sysctl.conf
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
kernel.randomize_va_space = 1
fs.file-max = 65535
kernel.pid_max = 65536
net.ipv4.ip_local_port_range = 2000 65000
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_max_syn_backlog = 3240000
net.ipv4.tcp_fin_timeout = 15
net.core.somaxconn = 65535
net.ipv4.tcp_max_tw_buckets = 1440000
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = cubic
vm.swappiness = 1
net.ipv4.tcp_tw_reuse = 1

EOF

# set all sysctl configurations
sysctl -p

# echo disable swap noop scheduler
# swapoff -a
# echo 'never' | tee /sys/kernel/mm/transparent_hugepage/enabled
echo 'noop' | tee /sys/block/sda/queue/scheduler
echo "block/sda/queue/scheduler = noop" >> /etc/sysfs.conf
# echo "kernel/mm/transparent_hugepage/enabled = never" >> /etc/sysfs.conf

systemctl daemon-reload

echo install clickhouse
#echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" > /etc/apt/sources.list.d/clickhouse.list

apt-get install apt-transport-https ca-certificates dirmngr
apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4

echo "deb https://repo.clickhouse.tech/deb/stable/ main/" | sudo tee \
    /etc/apt/sources.list.d/clickhouse.list

apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get \
    -o Dpkg::Options::="--force-confnew" \
    --force-yes \
    -fuy \
    dist-upgrade && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get \
    -o Dpkg::Options::="--force-confnew" \
    --force-yes \
    -fuy \
    install clickhouse-client=21.9.4.35 clickhouse-server=21.9.4.35 clickhouse-common-static=21.9.4.35

service clickhouse-server stop
/etc/init.d/clickhouse-server stop
killall clickhouse-server && sleep 5

cat <<EOF > /etc/clickhouse-server/config.xml
<?xml version="1.0"?>
<yandex>
    <logger>
        <level>warning</level>
        <log>/var/log/clickhouse-server/clickhouse-server.log</log>
        <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
        <size>1000M</size>
        <count>7</count>
    </logger>
    <display_name>ot-genetics</display_name>
    <http_port>8123</http_port>
    <tcp_port>9000</tcp_port>
    <interserver_http_port>9009</interserver_http_port>
    <listen_host>::</listen_host>
    <listen_host>0.0.0.0</listen_host>
    <listen_try>0</listen_try>
    <listen_reuse_port>1</listen_reuse_port>
    <listen_backlog>256</listen_backlog>
    <max_connections>2048</max_connections>
    <keep_alive_timeout>60</keep_alive_timeout>
    <max_concurrent_queries>256</max_concurrent_queries>
    <max_open_files>262144</max_open_files>
    <uncompressed_cache_size>17179869184</uncompressed_cache_size>
    <mark_cache_size>17179869184</mark_cache_size>
    <!-- Path to data directory, with trailing slash. -->
    <path>/var/lib/clickhouse/</path>
    <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
    <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>
    <users_config>users.xml</users_config>
    <default_profile>default</default_profile>
    <!-- <system_profile>default</system_profile> -->
    <default_database>default</default_database>
    <umask>022</umask>
    <zookeeper incl="zookeeper-servers" optional="true" />
    <macros incl="macros" optional="true" />
    <dictionaries_config>*_dictionary.xml</dictionaries_config>
    <builtin_dictionaries_reload_interval>3600</builtin_dictionaries_reload_interval>
    <max_session_timeout>3600</max_session_timeout>
    <default_session_timeout>60</default_session_timeout>
    <distributed_ddl>
        <path>/clickhouse/task_queue/ddl</path>
    </distributed_ddl>
    <format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>
</yandex>
EOF

cat <<EOF > /etc/clickhouse-server/users.xml
<?xml version="1.0"?>
<yandex>
    <profiles>
        <default>
            <max_memory_usage>30000000000</max_memory_usage>
		    <max_bytes_before_external_sort>20000000000</max_bytes_before_external_sort>
		    <max_bytes_before_external_group_by>20000000000</max_bytes_before_external_group_by>
            <use_uncompressed_cache>1</use_uncompressed_cache>
            <load_balancing>random</load_balancing>
            <max_query_size>1048576</max_query_size>
        </default>
        <readonly>
            <max_memory_usage>30000000000</max_memory_usage>
		    <max_bytes_before_external_sort>20000000000</max_bytes_before_external_sort>
		    <max_bytes_before_external_group_by>20000000000</max_bytes_before_external_group_by>
            <use_uncompressed_cache>1</use_uncompressed_cache>
            <load_balancing>random</load_balancing>
            <readonly>128</readonly>
            <max_query_size>1048576</max_query_size>
        </readonly>
    </profiles>
    <users>
        <default>
            <password></password>
            <networks incl="networks" replace="replace">
                <ip>::/0</ip>
                <ip>0.0.0.0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
        </default>
        <readonly>
            <password></password>
            <networks incl="networks" replace="replace">
                <ip>::/0</ip>
                <ip>0.0.0.0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
        </readonly>
    </users>
    <quotas>
        <default>
            <interval>
                <duration>3600</duration>
                <queries>0</queries>
                <errors>0</errors>
                <result_rows>0</result_rows>
                <read_rows>0</read_rows>
                <execution_time>0</execution_time>
            </interval>
        </default>
    </quotas>
</yandex>
EOF


mkdir /etc/clickhouse-server/dictionaries
chown -R clickhouse:clickhouse dictionaries/

systemctl enable clickhouse-server
systemctl start clickhouse-server

echo "starting clickhouse... done."

echo "Next step is loading the data"

echo touching $OT_RCFILE
echo "cluster_id=$cluster_id" > $OT_RCFILE
date >> $OT_RCFILE

echo "Google Storage info:"
echo ${GS_ETL_DATASET}

# Retrieve the table and database for clickhouse
wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/CH/literature.sql
wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/CH/literature_log.sql
wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/CH/w2v.sql
wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/CH/w2v_log.sql
wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/CH/aotf.sql
wget https://raw.githubusercontent.com/opentargets/platform-output-support/main/scripts/CH/aotf_log.sql

clickhouse-client --multiline --multiquery < aotf_log.sql
echo "create and fill in aotf_log"
gsutil -m cat gs://${GS_ETL_DATASET}/etl/json/AOTFClickhouse/part\* | clickhouse-client -h localhost --query="insert into ot.associations_otf_log format JSONEachRow "
echo "create and fill in Association on the fly table"
clickhouse-client --multiline --multiquery < aotf.sql
echo "Association on the fly table done"

clickhouse-client --multiline --multiquery < literature_log.sql
gsutil -m cat gs://${GS_ETL_DATASET}/literature-etl/parquet/literatureIndex/part\* | clickhouse-client -h localhost --query="insert into ot.literature_log format Parquet"
clickhouse-client --multiline --multiquery < literature.sql
echo "Literature table done"

clickhouse-client --multiline --multiquery < w2v_log.sql
gsutil -m cat gs://${GS_ETL_DATASET}/literature-etl/parquet/vectors/part\* | clickhouse-client -h localhost --query="insert into ot.ml_w2v_log format Parquet"
clickhouse-client --multiline --multiquery < w2v.sql
echo "Literature vectors done"

# This tag is waited by the POS VM in order to stop the VM and create the image of CH
gcloud --project ${PROJECT_ID} compute instances add-tags $HOSTNAME --zone ${GC_ZONE}  --tags "startup-done"
