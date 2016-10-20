require 'spec_helper'

describe DopCommon::Interface do
  before(:each) do
    @networks = {
      :valid_defgw => [DopCommon::Network.new(
        'valid_defgw', {
          'ip_pool'    => {'from' => '192.168.1.100', 'to' => '192.168.1.200'},
          'ip_netmask' => '255.255.255.0',
          'ip_defgw'   => '192.168.1.254'
        }
      )],
      :valid_nodefgw => [DopCommon::Network.new(
        'valid_nodefgw', {
          'ip_pool'    => {'from' => '192.168.1.100', 'to' => '192.168.1.200'},
          'ip_netmask' => '255.255.255.0',
          'ip_defgw'   => false
        }
      )]
    }
  end

  describe '#network' do
    it 'will return a network name in case it is defined in networks hash' do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'valid_defgw'},
        {:parsed_networks => @networks[:valid_defgw]}
      )
      expect(interface.network).to eq @networks[:valid_defgw].first.name
    end
    it "will raise an error if network name is invalid" do
      [nil, [], {}, "", 1].each do |n|
        interface = DopCommon::Interface.new(
          'eth0',
          {'network' => n},
          {:parsed_networks => @networks[:valid_defgw]}
        )
        expect{interface.network}.to raise_error DopCommon::PlanParsingError
      end
    end
    it "will raise an error if the network points to invalid network definition" do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'invalid definition', 'ip' => '192.168.1.101'},
        {:parsed_networks => @networks[:valid_defgw]}
      )
      expect{interface.network}.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#ip' do
    it "will return :dhcp if 'dhcp' is specified" do
      interface = DopCommon::Interface.new('eth0', {:ip => 'dhcp'})
      expect(interface.ip).to eq(:dhcp)
    end
    it "will return 'none' if none is specified" do
      interface = DopCommon::Interface.new('eth0', {:ip => 'none'})
      expect(interface.ip).to eq(:none)
    end
    it 'will return an IP if specified correctly' do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'valid_defgw', 'ip' => '192.168.1.101'},
        {:parsed_networks => @networks[:valid_defgw]}
      )
      expect(interface.ip).to eq('192.168.1.101')
    end
    it 'will raise an error if the ip is not valid' do
      interface = DopCommon::Interface.new('eth0', {'ip' => 'not valid ip'})
      expect{interface.ip}.to raise_error DopCommon::PlanParsingError
      interface = DopCommon::Interface.new('eth0', {'ip' => 2})
      expect{interface.ip}.to raise_error DopCommon::PlanParsingError
      interface = DopCommon::Interface.new('eth0', {'ip' => '300.0.0.0'})
      expect{interface.ip}.to raise_error DopCommon::PlanParsingError
      %w(192.168.1.202 192.168.1.254).each do |ip|
        interface = DopCommon::Interface.new(
          'eth0',
          {'network' => 'valid_defgw', 'ip' => ip},
          {:parsed_networks => @networks[:valid_defgw]}
        )
        expect{interface.ip}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#netmask' do
    it 'will return a netmask if specified correctly' do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'valid_defgw', 'ip' => '192.168.1.101'},
        {:parsed_networks => @networks[:valid_defgw]}
      )
      netmask = @networks[:valid_defgw].first.ip_netmask.to_s
      expect(interface.netmask).to eq(netmask)
    end
  end

  describe '#gateway' do
    it 'will return a gateway if specified correctly' do
      %w(valid_defgw valid_nodefgw).each do |n|
        interface = DopCommon::Interface.new(
          'eth0',
          {'network' => n, 'ip' => '192.168.1.101'},
          {:parsed_networks => @networks[n.to_sym]}
        )
        gateway = @networks[n.to_sym].first.ip_defgw.to_s
        expect(interface.gateway.to_s).to eq(gateway)
      end
    end
  end

  describe '#set_gateway?' do
    it 'will return true if not specified and network definition contains a default gateway' do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'valid_defgw', 'ip' => '192.168.1.101'},
        {:parsed_networks => @networks[:valid_defgw]}
      )
      expect(interface.set_gateway?).to eq(true)
    end
    [true, false].each do |v|
      it "will return #{v} if specified and network definition contains a default gateway" do
        interface = DopCommon::Interface.new(
          'eth0',
          {'network' => 'valid_defgw', 'ip' => '192.168.1.101', 'set_gateway' => v},
          {:parsed_networks => @networks[:valid_defgw]}
        )
        expect(interface.set_gateway?).to eq(v)
      end
    end
    it 'will return false if not specified and network definition does not contain a default gateway' do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'valid_nodefgw', 'ip' => '192.168.1.101'},
        {:parsed_networks => @networks[:valid_nodefgw]}
      )
      expect(interface.set_gateway?).to eq(false)
    end
    it 'will raise an error if not specified correctly' do
      [[], {}, 0, 1, 'foo'].each do |v|
        interface = DopCommon::Interface.new(
          'eth0',
          {'network' => 'valid_defgw', 'ip' => '192.168.1.101', 'set_gateway' => v},
          {:parsed_networks => @networks[:valid_defgw]}
        )
        expect{interface.set_gateway?}.to raise_error DopCommon::PlanParsingError
      end
    end
    it "will raise an error if set to 'true' and network definition does not contain a default gateway" do
      interface = DopCommon::Interface.new(
        'eth0',
        {'network' => 'valid_nodefgw', 'ip' => '192.168.1.101', 'set_gateway' => true},
        {:parsed_networks => @networks[:valid_nodefgw]}
      )
      expect{interface.set_gateway?}.to raise_error DopCommon::PlanParsingError
    end
  end
  describe '#virtual_switch' do
    it 'will return a virtual switch name if specified correctly' do
      ['foo', 'foo123', '123', 'foo bar', 'foo-bar', nil].each do |s|
        interface = DopCommon::Interface.new('eth0', {'virtual_switch' => s})
        expect(interface.virtual_switch).to be_a_kind_of(s.class)
        expect(interface.virtual_switch).to eq s
      end
    end
    it "will raise an error if the virtual switch definition isn't valid" do
      [123, {}, [], ""].each do |s|
        interface = DopCommon::Interface.new('eth0', {'virtual_switch' => s})
        expect{interface.virtual_switch}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#floating_network' do
    it 'will return nil if not specified' do
      interface = DopCommon::Interface.new('eth0', {})
      expect(interface.floating_network).to eq(nil)
    end
    it 'will return an IP network if specified properly' do
      interface = DopCommon::Interface.new('eth0', {'floating_network' => '172.16.3.0'})
      expect(interface.floating_network).to eq('172.16.3.0')
    end
    it 'will raise an error if not specified correctly' do
      [{}, [], 'foo', '300.0.1.25', '', 1].each do |n|
        interface = DopCommon::Interface.new('eth0', {'floating_network' => n})
        expect{interface.floating_network}.to raise_error DopCommon::PlanParsingError
      end
    end
  end
end

