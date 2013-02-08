## lb agent
template "/etc/init/lb_agent.conf" do
  source "lb_agent.upstart.erb"
  variables({
              :lb_agent_bin => node.lb_agent.bin
            })
end

service "lb_agent" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
