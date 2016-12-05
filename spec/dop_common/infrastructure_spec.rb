require 'spec_helper'

describe DopCommon::Infrastructure do

  describe '#provider' do
    it 'will set and return the infrastructure type of infrastructure if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.provider).to eq(:rhev)
    end
    it 'will raise an error if the type is missing' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {})
      expect { infrastructure.provider }.to raise_error ::DopCommon::PlanParsingError
    end
    it 'will raise an error ig the infrastructure provider type is invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'invalid'})
      expect { infrastructure.provider }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#endpoint' do
    it 'will set and return an URL object of infrastructure endpoint if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'baremetal'})
      expect(infrastructure.endpoint.to_s).to eq('')
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'endpoint' => 'https://foo.bar/baz'})
      expect(infrastructure.endpoint.to_s).to eq('https://foo.bar/baz')
    end
    it 'will raise an error if endpoint is unspecified and the cloud provider is not of baremetal type' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect { infrastructure.endpoint }.to raise_error ::DopCommon::PlanParsingError
    end
    it 'will raise an error if the endpoint specification is invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'endpoint' => nil})
      expect { infrastructure.endpoint }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#networks' do
    it 'will set and return networks if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'baremetal'})
      expect(infrastructure.networks).to eq([])
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'networks' => {'net1' => {}}})
      expect(infrastructure.networks.find { |n| n.name == 'net1' }).to be_a ::DopCommon::Network
    end
    it 'will raise an error if network specification is invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect { infrastructure.networks }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#affinity_groups' do
    it 'will set and return affinity groups if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => {}})
      expect(infrastructure.affinity_groups).to eq([])
    end
    it 'will raise an error in case of invalid specification of affinity groups' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => :invalid})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#default_security_groups' do
    it 'will return an empty array if not defined' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.default_security_groups).to eq([])
    end
    it 'will return an array of security groups if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'default_security_groups' => ['sg1', 'sg2']})
      expect(infrastructure.default_security_groups).to eq(['sg1', 'sg2'])
    end
    it 'will raise an error if the security groups is not specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'default_security_groups' => 1})
      expect { infrastructure.default_security_groups }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'default_security_groups' => [ 1, 2 ]})
      expect { infrastructure.default_security_groups }.to raise_error ::DopCommon::PlanParsingError
    end
  end
end
