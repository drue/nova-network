node["quantum"]["ovs"]["internal_interfaces"].split(",").each{|interface|
  execute "create internal bridge" do
    command "ovs-vsctl add-br br-#{interface}; ovs-vsctl add-port br-#{interface} #{interface}"
    action :run
    not_if "ovs-vsctl br-exists br-#{interface}" ## FIXME
  end
}

execute "create integration bridge" do
    command "ovs-vsctl add-br #{node["quantum"]["ovs"]["integration_bridge"]}"
    action :run
    not_if "ovs-vsctl br-exists br-int" ## FIXME
end
