# Doc at https://docs.vagrantup.com
# Boxes at https://vagrantcloud.com/search
require 'open-uri'

Vagrant.require_version ">= 2.2.4"

hosts = {
  masters: [1].map { |i| "master-node-#{i}" },
  workers: (1..2).map { |i| "worker-node-#{i}" }
}

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.box_version = "= 9.9.1"
  
  config.vm.network "private_network", type: "dhcp"

  # greet from every configured VM, revealing its hostname
  config.vm.provision "shell", inline: "echo Hello from \$HOSTNAME"

  # complete the ansible inventory with groups
  config.trigger.before :up do |trigger|
    inventory = File.open("./inventory/generated", "w")
    all_hosts = []

    hosts.keys.each do |group_name| 
      inventory.puts "[#{group_name}]"
      hosts[group_name].each do |node_name|
        inventory.puts node_name
        all_hosts << node_name
      end
    end

    inventory.puts "[etcd_peers]"
    hosts[:masters].each do |node_name|
        inventory.puts node_name
      end
  
  end

  # provision the vms
  hosts.keys.each do |node_group| 
    hosts[node_group].each do |node_name|

      config.vm.define node_name do |node|
        node.vm.hostname = node_name
        
        node.vm.provider :virtualbox do |v|
          v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
          v.customize ["modifyvm", :id, "--memory", 512]
          v.customize ["modifyvm", :id, "--name", node_name]
        end
      end
      
    end
  end

end
