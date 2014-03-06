require_relative "base"

module VagrantPlugins
  module Ansible
    module Provisioner
      class Host < Base

        def initialize(machine, config)
          super
          # TODO namings: ansible vs ansible_from_host vs ansible_ssh vs ansible_remote vs ...
          @logger = Log4r::Logger.new("vagrant::provisioners::ansible_host")
        end

        def provision
          @ssh_info = @machine.ssh_info
          # TODO lazy access to args and vars
          load_command_arguments
          load_environment_variables
          execute_ansible_playbook_from_host
        end

        protected

        def load_command_arguments
          # Connect with Vagrant SSH identity
          @command_arguments = %W[--private-key=#{@ssh_info[:private_key_path][0]} --user=#{@ssh_info[:username]}]

          # Multiple SSH keys and/or SSH forwarding can be passed via
          # ANSIBLE_SSH_ARGS environment variable, which requires 'ssh' mode.
          # Note that multiple keys and ssh-forwarding settings are not supported
          # by deprecated 'paramiko' mode.
          @command_arguments << "--connection=ssh" unless ansible_ssh_args.empty?

          load_common_command_arguments

          @command_arguments << "--ask-sudo-pass" if config.ask_sudo_pass
          @command_arguments << "--ask-vault-pass" if config.ask_vault_pass
        end

        def load_environment_variables
          load_common_environment_variables
          @environment_variables["ANSIBLE_HOST_KEY_CHECKING"] = "#{config.host_key_checking}"
          @environment_variables["ANSIBLE_SSH_ARGS"] = ansible_ssh_args unless ansible_ssh_args.empty?
        end

        def execute_ansible_playbook_from_host
          # Assemble the full ansible-playbook command
          command = (%w(ansible-playbook) << @command_arguments << config.playbook).flatten

          # Show the ansible command in use
          @machine.env.ui.detail(self.class.stringify_ansible_playbook_command(@environment_variables, command)) if config.verbose

          # Write stdout and stderr data, since it's the regular Ansible output
          command << {
            env: @environment_variables,
            notify: [:stdout, :stderr],
            workdir: @machine.env.root_path.to_s
          }

          begin
            result = Vagrant::Util::Subprocess.execute(*command) do |type, data|
              if type == :stdout || type == :stderr
                @machine.env.ui.info(data, new_line: false, prefix: false)
              end
            end
            raise Vagrant::Errors::AnsibleFailed if result.exit_code != 0
          rescue Vagrant::Util::Subprocess::LaunchError
            raise Vagrant::Errors::AnsiblePlaybookAppNotFound
          end
        end

        def ship_generated_inventory
          @inventory_path = Pathname.new(File.join('.vagrant', 'provisioners', 'ansible', 'inventory'))
          FileUtils.mkdir_p(@inventory_path) unless File.directory?(@inventory_path)
          FileUtils.mv(@inventory.to_s, @inventory_path.join('vagrant_ansible_inventory'))
        end

        def generate_inventory_machines(inventory_file)
          @machine.env.active_machines.each do |am|
            begin
              m = @machine.env.machine(*am)
              if !m.ssh_info.nil?
                inventory_file.write("#{m.name} ansible_ssh_host=#{m.ssh_info[:host]} ansible_ssh_port=#{m.ssh_info[:port]}\n")
                @inventory_machines[m.name] = m
              else
                @logger.error("Auto-generated inventory: Impossible to get SSH information for machine '#{m.name} (#{m.provider_name})'. This machine should be recreated.")
                # Let a note about this missing machine
                inventory_file.write("# MISSING: '#{m.name}' machine was probably removed without using Vagrant. This machine should be recreated.\n")
              end
            rescue Vagrant::Errors::MachineNotFound => e
              @logger.info("Auto-generated inventory: Skip machine '#{am[0]} (#{am[1]})', which is not configured for this Vagrant environment.")
            end
          end
        end

        def ansible_ssh_args
          @ansible_ssh_args ||= get_ansible_ssh_args
        end

        def get_ansible_ssh_args
          ssh_options = []

          # Multiple Private Keys
          @ssh_info[:private_key_path].drop(1).each do |key|
            ssh_options << "-o IdentityFile=#{key}"
          end

          # SSH Forwarding
          ssh_options << "-o ForwardAgent=yes" if @ssh_info[:forward_agent]

          # Unchecked SSH Parameters
          ssh_options.concat(self.class.as_array(config.raw_ssh_args)) if config.raw_ssh_args

          # Re-enable ControlPersist Ansible defaults,
          # which are lost when ANSIBLE_SSH_ARGS is defined.
          unless ssh_options.empty?
            ssh_options << "-o ControlMaster=auto"
            ssh_options << "-o ControlPersist=60s"
            # Intentionally keep ControlPath undefined to let ansible-playbook
            # automatically sets this option to Ansible default value
          end

          ssh_options.join(' ')
        end

      end
    end
  end
end
