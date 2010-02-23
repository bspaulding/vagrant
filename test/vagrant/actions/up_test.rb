require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class UpActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::Up)
    mock_config
  end

  context "sub-actions" do
    setup do
      @default_order = [Vagrant::Actions::ForwardPorts, Vagrant::Actions::SharedFolders, Vagrant::Actions::Start]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @mock_vm.expects(:add_action).with(Vagrant::Actions::Import, nil).once.in_sequence(default_seq)
      @default_order.each do |action|
        @mock_vm.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "add in the provisioning step if enabled" do
      mock_config do |config|
        config.chef.enabled = true
      end

      @default_order.push(Vagrant::Actions::Provision)
      setup_action_expectations
      @action.prepare
    end

    should "add in the action to move hard drive if config is set" do
      mock_config do |config|
        File.expects(:directory?).with("foo").returns(true)
        config.vm.hd_location = "foo"
      end

      @default_order.insert(0, Vagrant::Actions::MoveHardDrive)
      setup_action_expectations
      @action.prepare
    end
  end

  context "callbacks" do
    should "call persist and mac address setup after import" do
      boot_seq = sequence("boot")
      @action.expects(:persist).once.in_sequence(boot_seq)
      @action.expects(:setup_mac_address).once.in_sequence(boot_seq)
      @action.after_import
    end

    should "setup the root directory shared folder" do
      expected = ["vagrant-root", Vagrant::Env.root_path, Vagrant.config.vm.project_directory]
      assert_equal expected, @action.collect_shared_folders
    end
  end

  context "persisting" do
    should "persist the VM with Env" do
      @vm.stubs(:uuid)
      Vagrant::Env.expects(:persist_vm).with(@vm).once
      @action.persist
    end
  end

  context "setting up MAC address" do
    should "match the mac address with the base" do
      nic = mock("nic")
      nic.expects(:macaddress=).once

      @vm.expects(:nics).returns([nic]).once
      @vm.expects(:save).with(true).once

      @action.setup_mac_address
    end
  end
end