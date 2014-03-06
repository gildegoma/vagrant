require "vagrant"

module VagrantPlugins
  module Ansible
    class Plugin < Vagrant.plugin("2")
      name "ansible"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Ansible playbooks from Vagrant host or Vagrant guests.
      DESC

      config("ansible", :provisioner) do
        require_relative "config/host"
        Config::Host
      end

      config("ansible-local", :provisioner) do
        require_relative "config/guest"
        Config::Guest
      end

      provisioner("ansible") do
        require_relative "provisioner/host"
        Provisioner::Host
      end

      # TODO: what about :ansible_on_guest ?
      # Note that having '-' in provisioner name prevents from using :symbol syntax
      # Note that 'ansible-local' corresponds to http://www.packer.io/docs/provisioners/ansible-local.html

      provisioner("ansible-local") do
        require_relative "provisioner/guest"
        Provisioner::Guest
      end
    end
  end
end
