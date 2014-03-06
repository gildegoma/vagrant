require_relative "base"

module VagrantPlugins
  module Ansible
    module Config
      class Host < Base
        attr_accessor :ask_sudo_pass
        attr_accessor :ask_vault_pass
        attr_accessor :host_key_checking

        # Joker attribute, used to set additional SSH parameters for ansible-playbook anyway
        attr_accessor :raw_ssh_args

        def initialize
          super
          @ask_sudo_pass       = UNSET_VALUE
          @ask_vault_pass      = UNSET_VALUE
          @host_key_checking   = UNSET_VALUE
          @raw_ssh_args        = UNSET_VALUE
        end

        def finalize!
          super
          @ask_sudo_pass       = false unless @ask_sudo_pass == true
          @ask_vault_pass      = false unless @ask_vault_pass == true
          @host_key_checking   = false unless @host_key_checking == true
          @raw_ssh_args        = nil if @raw_ssh_args == UNSET_VALUE
        end

        def validate(machine)
          errors = _detected_errors
          errors.concat(validate_base(machine))

          # Validate the existence of said playbook on the host
          if playbook
            expanded_path = Pathname.new(playbook).expand_path(machine.env.root_path)
            if !expanded_path.file?
              errors << I18n.t("vagrant.provisioners.ansible.playbook_path_invalid",
                                path: expanded_path)
            end
          end

          # Validate the existence of the inventory_path, if specified
          if inventory_path
            expanded_path = Pathname.new(inventory_path).expand_path(machine.env.root_path)
            if !expanded_path.exist?
              errors << I18n.t("vagrant.provisioners.ansible.inventory_path_invalid",
                                path: expanded_path)
            end
          end

          # Validate the existence of the vault_password_file, if specified
          if vault_password_file
            expanded_path = Pathname.new(vault_password_file).expand_path(machine.env.root_path)
            if !expanded_path.exist?
              errors << I18n.t("vagrant.provisioners.ansible.vault_password_file_invalid",
                                path: expanded_path)
            end
          end

          # TODO: extra_vars sanity checks should also be available for guest-based provisioning
          # Validate that extra_vars is either a hash, or a path to an
          # existing file
          if extra_vars
            extra_vars_is_valid = extra_vars.kind_of?(Hash) || extra_vars.kind_of?(String)
            if extra_vars.kind_of?(String)
              # Accept the usage of '@' prefix in Vagrantfile (e.g. '@vars.yml'
              # and 'vars.yml' are both supported)
              match_data = /^@?(.+)$/.match(extra_vars)
              extra_vars_path = match_data[1].to_s
              expanded_path = Pathname.new(extra_vars_path).expand_path(machine.env.root_path)
              extra_vars_is_valid = expanded_path.exist?
              if extra_vars_is_valid
                @extra_vars = '@' + extra_vars_path
              end
            end

            if !extra_vars_is_valid
              errors << I18n.t("vagrant.provisioners.ansible.extra_vars_invalid",
                                type:  extra_vars.class.to_s,
                                value: extra_vars.to_s
                              )
            end
          end

          # TODO switch to "ansible host provisioner" or alike (unit tests to be adapted...)
          { "ansible provisioner" => errors }
        end

      end
    end
  end
end
