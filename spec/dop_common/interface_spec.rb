require 'spec_helper'

describe DopCommon::Node do

  describe '#ip' do
    it 'will return :dhcp if dhcp is specified' do
      interface = DopCommon::Interface.new('eth0', {:ip => 'dhcp'})
      expect(interface.ip).to eq(:dhcp)
    end
    it 'will return the ip if a correct ip is specified' do
      interface = DopCommon::Interface.new('eth0', {:ip => '192.168.0.1'})
      expect(interface.ip).to eq('192.168.0.1')
    end
    it 'will raise an error if the ip is not valid' do
      interface = DopCommon::Interface.new('eth0', {:ip => 'not valid ip'})
      expect{interface.ip}.to raise_error DopCommon::PlanParsingError
      interface = DopCommon::Interface.new('eth0', {:ip => 2})
      expect{interface.ip}.to raise_error DopCommon::PlanParsingError
      interface = DopCommon::Interface.new('eth0', {:ip => '300.0.0.0'})
      expect{interface.ip}.to raise_error DopCommon::PlanParsingError
    end
  end

end

