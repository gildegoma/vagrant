require_relative "base"

module VagrantPlugins
  module Ansible
    module Config
      class Guest < Base
        attr_accessor :provisioning_path
        attr_accessor :tmp_path

        def initialize
          super
          @provisioning_path = UNSET_VALUE
          @tmp_path          = UNSET_VALUE
        end

        def finalize!
          super
          # TODO: should provisioning_path default ("/vagrant") be replaced by fetching the default/first shared folder path?
          #       useful in case /vagrant shared folder has been disabled, but not absoluetly mandatory
          @provisioning_path = "/vagrant" if provisioning_path == UNSET_VALUE
          @tmp_path          = "/tmp/vagrant-ansible" if tmp_path == UNSET_VALUE
        end

        def validate(machine)
          errors = _detected_errors
          errors.concat(validate_base(machine))

          # TODO verify that @provisioning_path remote folder exists on the guest system
          # TODO: extra_vars sanity checks should also be available for guest-based provisioning

          # Not sure if absolutely necessary to be validated:
          # TODO Validate the existence of said playbook on the guest system
          # TODO Validate the existence of the inventory_path (if specified) on the guest system ? (or @inventory_path)
          # TODO Validate the existence of the vault_password_file on the guest system ?

          # Basic example:
          # remote_playbook = File.join(@provisioning_path, @playbook)
          # if !machine.communicate.test("test -f #{remote_playbook}")
          #   errors << I18n.t("vagrant.provisioners.ansible.playbook_path_invalid",
          #                     path: remote_playbook)
          # end

          { "ansible guest provisioner" => errors }
        end

      end
    end
  end
end
