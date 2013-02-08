include_recipe "python"
include_recipe "osops-utils"
include_recipe "mysql"
include_recipe "monit"

if not node["package_component"].nil?
  release = node["package_component"]
else
  release = "folsom"
end


python_pip "/project/worm" do
  action [:install]
end


## linux bridge specific stuff
mysql_info = get_settings_by_role("mysql-master", "mysql")
connection_info = {:host => mysql_info["bind_address"], :username => "root", :password => mysql_info["server_root_password"]}

mysql_database "create quantum_linux_bridge db" do
  connection connection_info
  database_name node["quantum"]["worm"]["db_name"]
  action :create
end

mysql_database_user node["quantum"]["db"]["username"] do
  connection connection_info
  database_name node["quantum"]["worm"]["db_name"]
  password node["quantum"]["db"]["password"]
  host '%'
  privileges [:all]
  action :grant
end



api_endpoint = get_bind_endpoint("quantum", "api")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
local_ip = get_ip_for_net('nova', node)		### FIXME
quantum_info = get_settings_by_recipe("nova-network::nova-controller", "quantum")

template "/etc/quantum/api-paste.ini" do
    source "#{release}/api-paste.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        "keystone_api_ipaddress" => ks_admin_endpoint["host"],
        "keystone_admin_port" => ks_admin_endpoint["port"],
        "keystone_protocol" => ks_admin_endpoint["scheme"],
        "service_tenant_name" => quantum_info["service_tenant_name"],
        "service_user" => quantum_info["service_user"],
        "service_pass" => quantum_info["service_pass"]
    )
end

template "/etc/quantum/quantum.conf" do
  source "#{release}/quantum.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
            "quantum_debug" => node["quantum"]["debug"],
            "quantum_verbose" => node["quantum"]["verbose"],
            "quantum_ipaddress" => api_endpoint["host"],
            "quantum_port" => api_endpoint["port"],
            "rabbit_ipaddress" => rabbit_info["host"],
            "rabbit_port" => rabbit_info["port"],
            "overlapping_ips" => node["quantum"]["overlap_ips"],
            "quantum_plugin" => node["quantum"]["plugin"]
            )
  notifies :restart, "service[quantum-server]", :delayed
end

directory  "/etc/quantum/plugins/worm" do
  owner "quantum"
  group "quantum"
  mode "0755"
end

template node["quantum"]["worm"]["plugin_conf"] do
  source "#{release}/worm.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
            "db_ip_address" => mysql_info["host"],
            "db_user" => node["quantum"]["db"]["username"],
            "db_password" => node["quantum"]["db"]["password"],
            "db_name" => node["quantum"]["db"]["name"],
            "vlan_ranges" => node["quantum"]["worm"]["vlan_ranges"],
            "bridge_mappings" => node["quantum"]["worm"]["bridge_mappings"],
            "switches" => node["quantum"]["worm"]["switch_list"]
            )
  notifies :restart, "service[quantum-server]", :delayed
end

template "/etc/default/quantum-server" do
  source "#{release}/quantum_default.erb"
  variables(
            "plugin_conf" => node["quantum"]["worm"]["plugin_conf"]
            )
end


# ## temp XXX
# bash "flush eth2" do
#   code "ip address flush dev eth2;ifconfig eth2 up"
# end
