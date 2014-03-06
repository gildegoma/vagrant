require_relative "../../../../base"
require_relative "../../support/shared/config"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/base")

describe VagrantPlugins::Ansible::Config::Base do
  include_context "unit"

  subject { described_class.new }

  it "supports a list of options" do
    config_options = subject.public_methods(false).find_all { |i| i.to_s.end_with?('=') }
    config_options.map! { |i| i.to_s.sub('=', '') }
    supported_options = %w( extra_vars
                            groups
                            inventory_path
                            limit
                            playbook
                            raw_arguments
                            skip_tags
                            start_at_task
                            sudo
                            sudo_user
                            tags
                            vault_password_file
                            verbose )

    expect(config_options.sort).to eql(supported_options)
  end

  describe "sudo option" do
    it_behaves_like "any VagrantConfigProvisioner strict boolean attribute", :sudo, false
  end

end
