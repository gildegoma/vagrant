module VagrantPlugins
  module Ansible
    module Config
      class Base < Vagrant.plugin("2", :config)
        attr_accessor :playbook
        attr_accessor :extra_vars
        attr_accessor :inventory_path
        attr_accessor :vault_password_file
        attr_accessor :limit
        attr_accessor :sudo
        attr_accessor :sudo_user
        attr_accessor :verbose
        attr_accessor :tags
        attr_accessor :skip_tags
        attr_accessor :start_at_task
        attr_accessor :groups

        # Joker attribute, used to pass unsupported arguments to ansible-playbook anyway
        attr_accessor :raw_arguments

        def initialize
          @playbook            = UNSET_VALUE
          @extra_vars          = UNSET_VALUE
          @inventory_path      = UNSET_VALUE
          @vault_password_file = UNSET_VALUE
          @limit               = UNSET_VALUE
          @sudo                = UNSET_VALUE
          @sudo_user           = UNSET_VALUE
          @verbose             = UNSET_VALUE
          @tags                = UNSET_VALUE
          @skip_tags           = UNSET_VALUE
          @start_at_task       = UNSET_VALUE
          @groups              = UNSET_VALUE
          @raw_arguments       = UNSET_VALUE
        end

        def finalize!
          @playbook            = nil if @playbook == UNSET_VALUE
          @extra_vars          = nil if @extra_vars == UNSET_VALUE
          @inventory_path      = nil if @inventory_path == UNSET_VALUE
          @vault_password_file = nil if @vault_password_file == UNSET_VALUE
          @limit               = nil if @limit == UNSET_VALUE
          @sudo                = false unless @sudo == true
          @sudo_user           = nil if @sudo_user == UNSET_VALUE
          @verbose             = nil if @verbose == UNSET_VALUE
          @tags                = nil if @tags == UNSET_VALUE
          @skip_tags           = nil if @skip_tags == UNSET_VALUE
          @start_at_task       = nil if @start_at_task == UNSET_VALUE
          @groups              = {}  if @groups == UNSET_VALUE
          @host_key_checking   = false unless @host_key_checking == true
          @raw_arguments       = nil if @raw_arguments == UNSET_VALUE
          @raw_ssh_args        = nil if @raw_ssh_args == UNSET_VALUE
        end

        # Just like the normal configuration "validate" method except that
        # it returns an array of errors that should be merged into some
        # other error accumulator.
        def validate_base(machine)
          errors = _detected_errors

          # Validate that a playbook path was provided
          if !playbook
            errors << I18n.t("vagrant.provisioners.ansible.no_playbook")
          end

          # TODO extract (or abstract) the file existence validation (host vs guest)
          #
          # # Validate that extra_vars is either a hash, or a path to an
          # # existing file
          # if extra_vars
          #   extra_vars_is_valid = extra_vars.kind_of?(Hash) || extra_vars.kind_of?(String)
          #   if extra_vars.kind_of?(String)
          #     # Accept the usage of '@' prefix in Vagrantfile (e.g. '@vars.yml'
          #     # and 'vars.yml' are both supported)
          #     match_data = /^@?(.+)$/.match(extra_vars)
          #     extra_vars_path = match_data[1].to_s
          #     expanded_path = Pathname.new(extra_vars_path).expand_path(machine.env.root_path)
          #     extra_vars_is_valid = expanded_path.exist?
          #     if extra_vars_is_valid
          #       @extra_vars = '@' + extra_vars_path
          #     end
          #   end

          #   if !extra_vars_is_valid
          #     errors << I18n.t("vagrant.provisioners.ansible.extra_vars_invalid",
          #                       type:  extra_vars.class.to_s,
          #                       value: extra_vars.to_s
          #                     )
          #   end
          # end

          errors
        end
      end
    end
  end
end
