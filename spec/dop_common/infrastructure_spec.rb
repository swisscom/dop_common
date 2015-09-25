require 'spec_helper'

describe DopCommon::Infrastructure do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#provider' do
    it 'will set and return the infrastructure type of infrastructure if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.provider).to eq(:rhev)
    end
    it 'will raise an error if the type is unspecified and/or invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {})
      expect { infrastructure.provider }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'invalid'})
      expect { infrastructure.provider }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#endpoint' do
    it 'will set and return an URL object of infrastructure endpoint if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'baremetal'})
      expect(infrastructure.endpoint.to_s).to eq('')
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'endpoint' => 'https://foo.bar/endp'})
      expect(infrastructure.endpoint.to_s).to eq('https://foo.bar/endp')
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'baremetal', 'endpoint' => 'https://foo.bar/endp'})
      expect(infrastructure.endpoint.to_s).to eq('https://foo.bar/endp')
    end
    it 'will raise an error if endpoint is unspecified and the cloud provider is not of baremetal type' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev' })
    end
    it 'will raise an error if the endpoint specification is invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'endpoint' => {}})
      expect { infrastructure.endpoint }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'baremetal', 'endpoint' => {}})
      expect { infrastructure.endpoint }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#networks' do
    it 'will set and return networks if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.networks).to eq({})
      infrastructure = ::DopCommon::Infrastructure.new(
        'dummy',
        {
          'type' => 'rhev',
          'networks' => {
            'net1' => nil,
            'net2' => {'ip_defgw' => '172.17.27.1', 'netmask' => '255.255.255.0'}
          }
        }
      )
      expect(infrastructure.networks['net1']).to be_a ::DopCommon::Network
      expect(infrastructure.networks['net2']).to be_a ::DopCommon::Network
    end
    it 'will raise an error if network specification is invalid' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'networks' => 'invalid'})
      expect { infrastructure.networks }.to raise_error ::DopCommon::PlanParsingError
    end
  end

  describe '#affinity_groups' do
    it 'will set and return affinity groups if specified correctly' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev'})
      expect(infrastructure.affinity_groups).to eq({})
      infrastructure = ::DopCommon::Infrastructure.new(
        'dummy',
        {
          'type' => 'rhev',
          'affinity_groups' => {
            'ag1' => {'positive' => true, 'enforce' => false, 'cluster' => 'cl1'},
            'ag2' => {'positive' => false, 'enforce' => false, 'cluster' => 'cl1'}
          }
        }
      )
      expect(infrastructure.affinity_groups['ag1']).to be_a ::DopCommon::AffinityGroup
      expect(infrastructure.affinity_groups['ag2']).to be_a ::DopCommon::AffinityGroup
    end
    it 'will raise an error in case of invalid specification of affinity groups' do
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => 'invalid'})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => { :invalid => {}}})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
      infrastructure = ::DopCommon::Infrastructure.new('dummy', {'type' => 'rhev', 'affinity_groups' => { 'ag1' => 'invalid' }})
      expect { infrastructure.affinity_groups }.to raise_error ::DopCommon::PlanParsingError
    end
  end
end

