require_relative "base"

module VagrantPlugins
  module Ansible
    module Provisioner
      class Guest < Base

        def initialize(machine, config)
          super
           # TODO namings: ansible_local vs ansible_on_guest vs ...
          @logger = Log4r::Logger.new("vagrant::provisioners::ansible_guest")
        end

        def provision
          verify_guest_binary('ansible-playbook')
          # TODO lazy access to args and vars
          load_command_arguments
          load_common_environment_variables
          execute_ansible_playbook_on_guest
        end

        protected

        def load_command_arguments
          @command_arguments = []
          load_common_command_arguments
          @command_arguments << '--connection=local'
        end

        def execute_ansible_playbook_on_guest
          command = (%w(ansible-playbook) << @command_arguments << config.playbook).flatten
          remote_command = "cd #{config.provisioning_path} && #{self.class.stringify_ansible_playbook_command(@environment_variables, command)}"

          # Show the ansible command in use
          @machine.env.ui.detail(remote_command) if config.verbose

          result = execute_on_guest(remote_command)
          raise Vagrant::Errors::AnsibleFailed if result != 0
        end

        def execute_on_guest(command)
          @machine.communicate.execute(command, :error_check => false) do |type, data|
            if [:stderr, :stdout].include?(type)
              @machine.env.ui.info(data, :new_line => false, :prefix => false)
            end
          end
        end

        def ship_generated_inventory
          inventory_basedir = File.join(config.tmp_path, "inventory")
          @inventory_path = File.join(inventory_basedir, "vagrant_ansible_local_inventory")

          create_and_chown_remote_folder(inventory_basedir)
          @machine.communicate.tap do |comm|
            comm.sudo("rm -f #{@inventory_path}", error_check: false)
            comm.upload(@inventory.to_s, @inventory_path)
          end
        end

        def generate_inventory_machines(inventory_file)
          @inventory_machines[@machine.name] = @machine
          inventory_file.write("#{@machine.name}\n")
        end

        def verify_guest_binary(binary)
          # Checks for the existence of an ansible binary
          # and error if it doesn't exist.
          @machine.communicate.execute(
            "which #{binary}",
            :error_class => AnsibleError,
            :error_key => :not_detected,
            :binary => binary)
        end

        def create_and_chown_remote_folder(path)
          @machine.communicate.tap do |comm|
            comm.sudo("mkdir -p #{path}")
            comm.sudo("chown -h #{@machine.ssh_info[:username]} #{path}")
          end
        end

      end
    end
  end
end
