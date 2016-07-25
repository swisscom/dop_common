require 'spec_helper'

describe DopCommon::Network do

  good_ip_defgw = '192.168.1.1'
  good_ip_netmask = '255.255.255.0'
  good_net = {
    'ip_defgw' => good_ip_defgw,
    'ip_netmask' => good_ip_netmask
  }

  describe '#ip_defgw' do
    it 'will return a netmask object if the default gateway is correct' do
      network = DopCommon::Network.new('dummy', {})
      expect(network.ip_defgw).to be_nil
      network = DopCommon::Network.new('dummy', good_net)
      expect(network.ip_defgw.to_s).to eq(good_net['ip_defgw'])
    end
    it 'will return a netmask object if the default gateway is nil' do
      network = DopCommon::Network.new('dummy', good_net.merge('ip_defgw' => false))
      expect(network.ip_defgw).to be_falsey
    end
    it 'will raise an error in case of invalid default gateway IP' do
      network = DopCommon::Network.new('dummy', {'ip_defgw' => :invalid})
      expect { network.ip_defgw }.to raise_error DopCommon::PlanParsingError
    end
  end


  describe '#ip_netmask' do
    it 'will return a netmask object if the netmask is correct' do
      network = DopCommon::Network.new('dummy', {})
      expect(network.ip_netmask).to eq(nil)
      network = DopCommon::Network.new('dummy', {'ip_netmask' => good_ip_netmask})
      expect(network.ip_netmask.to_s).to eq(good_ip_netmask)
    end
    it 'will raise an error in case of invalid netmask' do
      network = DopCommon::Network.new('dummy', {'ip_netmask' => :invalid})
      expect { network.ip_netmask }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#ip_pool' do
    good_ip_from = '192.168.1.11'
    good_ip_to = '192.168.1.249'

    it 'will return an empty hash if "ip_pool" is unspecified' do
      network = DopCommon::Network.new('dummy', {})
      expect(network.ip_pool).to eq({})
    end

    it 'will return a hash with "from" and "to" if network is specified properly' do
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => {'from' => good_ip_from, 'to' => good_ip_to}))
      expect(network.ip_pool[:from].to_s).to eq(good_ip_from)
      expect(network.ip_pool[:to].to_s).to eq(good_ip_to)
    end

    it 'will raise an error if ip_pool is not a hash and any of "from" or "to" is not defined' do
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => :invalid))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => {'to' => good_ip_to}))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => {'from' => good_ip_from}))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
    end

    it 'will raise an error in case "from" is an invalid IP' do
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => {'from' => :invalid, 'to' => good_ip_to}))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
    end

    it 'will raise an error in case "to" is an invalid IP' do
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => {'from' => good_ip_from, 'to' => :invalid}))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
    end

    it 'will raise an error in case of invalid ip_pool specification (from > to)' do
      network = DopCommon::Network.new('dummy', good_net.merge('ip_pool' => {'from' => good_ip_to, 'to' => good_ip_from}))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
    end

    it 'will raise an error if the IP of default gateway is within IP pool range' do
      bad_net = {
        'ip_defgw' => good_ip_from,
        'ip_netmask' => good_net['ip_netmask']
      }
      network = DopCommon::Network.new('dummy', bad_net.merge('ip_pool' => {'from' => good_ip_to, 'to' => good_ip_from}))
      expect { network.ip_pool }.to raise_error DopCommon::PlanParsingError
    end
  end
end

