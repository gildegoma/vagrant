require_relative "../../../../base"
require_relative "../../support/shared/config"

require Vagrant.source_root.join("plugins/provisioners/ansible/config/guest")

describe VagrantPlugins::Ansible::Config::Guest do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine", env: Vagrant::Environment.new) }
  let(:existing_file) { File.expand_path(__FILE__) }
  let(:non_existing_file) { "/this/does/not/exist" }

  it "supports a list of options" do
    config_options = subject.public_methods(false).find_all { |i| i.to_s.end_with?('=') }
    config_options.map! { |i| i.to_s.sub('=', '') }
    supported_options = %w( provisioning_path
                            tmp_path )

    expect(config_options.sort).to eql(supported_options)
  end

  it "assigns default values to unset options" do
    subject.finalize!

    # Common options
    expect(subject.playbook).to be_nil
    expect(subject.extra_vars).to be_nil
    expect(subject.vault_password_file).to be_nil
    expect(subject.limit).to be_nil
    expect(subject.sudo).to be_false
    expect(subject.sudo_user).to be_nil
    expect(subject.verbose).to be_nil
    expect(subject.tags).to be_nil
    expect(subject.skip_tags).to be_nil
    expect(subject.start_at_task).to be_nil
    expect(subject.groups).to eq({})
    expect(subject.raw_arguments).to be_nil

    # Guest-specific options
    expect(subject.provisioning_path).to eql("/vagrant")
    expect(subject.tmp_path).to eql("/tmp/vagrant-ansible")
  end

  describe "#validate" do
    before do
      subject.playbook = existing_file
    end

    # TODO the check is different for host and guest provisioners!
    # TODO maybe just drop these features/tests for the guest-based case.
    xit "passes if the playbook option refers to an existing file" do
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible provisioner"]).to eql([])
    end

    # TODO the check is different for host and guest provisioners!
    xit "returns an error if the playbook file does not exist" do
      subject.playbook = non_existing_file
      subject.finalize!

      result = subject.validate(machine)
      expect(result["ansible provisioner"]).to eql([
        I18n.t("vagrant.provisioners.ansible.playbook_path_invalid",
               path: non_existing_file)
      ])
    end

  end

end
