require 'spec_helper'

describe DopCommon::Network do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#ip_netmask' do
    it 'will return netmask object if the netmask is correct' do
      network = DopCommon::Network.new('net0', {:ip_netmask => '255.255.255.0'})
      expect(network.ip_netmask.to_s).to eq('255.255.255.0')
    end
    it 'will raise an error in case of invalid netmask' do
      network = DopCommon::Network.new('net0', {:ip_netmask => '300.0.0.0'})
      expect { network.ip_netmask }.to raise_error DopCommon::PlanParsingError
      network = DopCommon::Network.new('net0', {:ip_netmask => 'invalid'})
      expect { network.ip_netmask }.to raise_error DopCommon::PlanParsingError
      network = DopCommon::Network.new('net0', {:ip_netmask => {:invalid => 'invalid'}})
      expect { network.ip_netmask }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#ip_defgw' do
    it 'will return default gateway object if its IP is correct' do
      network = DopCommon::Network.new('net0', {:ip_defgw => '192.168.2.254'})
      expect(network.ip_defgw.to_s).to eq('192.168.2.254')
    end
    it 'will raise an error in case of invalid netmask' do
      network = DopCommon::Network.new('net0', {:ip_defgw => '300.254.752.1'})
      expect { network.ip_defgw }.to raise_error DopCommon::PlanParsingError
      network = DopCommon::Network.new('net0', {:ip_defgw => 'invalid'})
      expect { network.ip_defgw }.to raise_error DopCommon::PlanParsingError
      network = DopCommon::Network.new('net0', {:ip_defgw => {:invalid => 'invalid'}})
      expect { network.ip_defgw }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#ip_pool' do
    it 'will return a hash with "from" and "to" IP objects if specified correctly' do
      # No IP pool specified
      network = DopCommon::Network.new('net0', {})
      expect(network.ip_pool).to eq(nil)
      # IP pool specified
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.2.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => '192.168.2.25',
            :to => '192.168.2.155'
          }
        }
      )
      expect(network.ip_pool[:from].to_s).to eq('192.168.2.25')
      expect(network.ip_pool[:to].to_s).to eq('192.168.2.155')
    end
    it 'will raise an error in case of invalid ip_pool, netmask or default gateway specification' do
      # Missing netmask and default gateway entry
      network = DopCommon::Network.new('net0', {:ip_pool => {:from => '192.168.2.25', :to => '192.168.2.155'}})
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # Missing netmask entry
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw => '192.168.2.254',
          :ip_pool => {:from => '192.168.2.25', :to => '192.168.2.155'}
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # Missing default gateway entry
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_netmask => '192.168.2.254',
          :ip_pool => {:from => '192.168.2.25', :to => '192.168.2.155'}
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # Invalid pool range specification
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.2.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => '192.168.2.234',
            :to => '192.168.2.155'
          }
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # The default GW is not from the same network the IP pool specifies
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.1.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => '192.168.2.25',
            :to => '192.168.2.155'
          }
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # The IP pool spans over more sub-networks
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.2.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => '192.168.2.25',
            :to => '192.168.4.155'
          }
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # The IP pool includes the ip of default gateway
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.2.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => '192.168.2.25',
            :to => '192.168.2.254'
          }
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # Invalid data specified in 'from' field of the IP pool
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.2.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => 'invalid',
            :to => '192.168.2.254'
          }
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      # Invalid data specified in 'to' field of the IP pool
      network = DopCommon::Network.new(
        'net0',
        {
          :ip_defgw   => '192.168.2.254',
          :ip_netmask => '255.255.255.0',
          :ip_pool    => {
            :from => '192.168.2.25',
            :to => { :invalid => nil }
          }
        }
      )
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
    end
  end
end

