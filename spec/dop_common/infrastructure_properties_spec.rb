require 'spec_helper'

describe DopCommon::InfrastructureProperties do

  providers = %w(ovirt vsphere openstack)
  infrastructure = Hash[
    providers.collect { |p| [p, DopCommon::Infrastructure.new(p, {'type' => p})] }
  ]

  describe '#affinity_groups' do
    it 'will return an array of affinity group if input is valid' do
      ags = ['ag1', 'ag2', 'ag3']
      infrastructure_properties = DopCommon::InfrastructureProperties.new({}, nil)
      expect(infrastructure_properties.affinity_groups).to eq []
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'affinity_groups' => ags}, nil)
      expect(infrastructure_properties.affinity_groups).to eq ags
    end

    it 'will raise an error if input affinity groups point to a non-empty array' do
      [[], 'invalid'].each do |val|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'affinity_groups' => val}, nil)
        expect { infrastructure_properties.affinity_groups }.to raise_error DopCommon::PlanParsingError
      end
    end

    it 'will raise an error if input affinity groups array contains invalid entries' do
      [[:ag1, "ag2", 2], ["ag1", 2, "ag3"], ["ag1", "ag2", ""]].each do |ag|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'affinity_groups' => ag}, nil)
        expect { infrastructure_properties.affinity_groups }.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#keep_ha?' do
    it "will return 'true' if not specified in input hash" do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({}, infrastructure['ovirt'])
      expect(infrastructure_properties.keep_ha?).to eq true
    end

    it "will return 'true' or 'false' if specified in input hash properly" do
      [true, false].each do |val|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'keep_ha' => val}, infrastructure['ovirt'])
        expect(infrastructure_properties.keep_ha?).to eq val
      end
    end

    it 'will raise an exception if used for non-openstack provider' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'keep_ha' => true}, infrastructure['vsphere'])
      expect { infrastructure_properties.keep_ha? }.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception if not specified properly in input hash' do
      ['true', 'false', 1, 0, :invalid, {}].each do |val|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'keep_ha' => val}, infrastructure['ovirt'])
        expect { infrastructure_properties.keep_ha? }.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  %w(datacenter cluster).each do |prop_name|
    describe "##{prop_name}" do
      providers.each do |p|
        it "will return the '#{prop_name}' name if specified correctly" do
          prop_val = "prop-val-#{p}"
          infrastructure_properties = DopCommon::InfrastructureProperties.new(
            {prop_name => prop_val},
            infrastructure[p]
          )
          expect(infrastructure_properties.send(prop_name.to_sym)).to eq(p == 'openstack' ? nil : prop_val)
        end

        it "will raise an exception if '#{prop_name}' is not specified properly" do
          unless p == 'openstack'
            [{}, :invalid, ""].each do |prop_val|
              infrastructure_properties = DopCommon::InfrastructureProperties.new(
                {prop_name => prop_val},
                infrastructure[p]
              )
              expect { infrastructure_properties.send(prop_name.to_sym) }.to raise_error DopCommon::PlanParsingError
            end
          end
        end
      end
    end
  end

  %w(default_pool dest_folder).each do |method_name|
    describe "##{method_name}" do
      it "will return 'nil' if not specified in input hash" do
        infrastructure_properties = DopCommon::InfrastructureProperties.new({}, nil)
        expect(infrastructure_properties.send(method_name.to_sym)).to eq nil
      end

      it "will return '#{method_name}' if specified properly in input hash" do
        infrastructure_properties = DopCommon::InfrastructureProperties.new({method_name => "foo-#{method_name}"}, nil)
        expect(infrastructure_properties.send(method_name.to_sym)).to eq "foo-#{method_name}"
      end

      it "will raise an exception if not specified properly in input hash" do
        ["", :invalid].each do |val|
          infrastructure_properties = DopCommon::InfrastructureProperties.new({method_name => val}, nil)
          expect { infrastructure_properties.send(method_name.to_sym) }.to raise_error DopCommon::PlanParsingError
        end
      end
    end
  end

  describe '#tenant' do
    providers.each do |p|
      it "will return the 'tenant' name if specified properly" do
        tenant = "tenant_#{p}"
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'tenant' => tenant}, infrastructure[p])
        expect(infrastructure_properties.tenant).to eq(p == 'openstack' ? tenant : nil)
      end
    end

    it "will raise an exception if provider is 'openstack' and 'tenant' is undefined" do
      [nil, :invalid, ""].each do |prop_val|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'tenant' => prop_val}, infrastructure['openstack'])
        expect { infrastructure_properties.tenant }.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#use_config_drive?' do
    it "will return false if not specified in input hash" do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({}, nil)
      expect(infrastructure_properties.use_config_drive?).to eq false
    end

    it "will return true or false if specified in input hash properly" do
      [true, false].each do |val|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'use_config_drive' => val}, infrastructure['openstack'])
        expect(infrastructure_properties.use_config_drive?).to eq val
      end
    end

    it 'will raise an exception if used for non-openstack provider' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'use_config_drive' => true}, infrastructure['ovirt'])
      expect { infrastructure_properties.use_config_drive? }.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an exception if not specified properly in input hash' do
      ['true', 'false', 1, 0, :invalid, {}].each do |val|
        infrastructure_properties = DopCommon::InfrastructureProperties.new({'use_config_drive' => val}, infrastructure['openstack'])
        expect { infrastructure_properties.use_config_drive? }.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#security_groups' do
    infra = DopCommon::Infrastructure.new('openstack', {'type' => 'openstack', 'default_security_groups' => ['sg1', 'sg2']})
    it 'will return the default_security_groups if nothing is specified' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({}, infra)
      expect(infrastructure_properties.security_groups).to eq(['sg1', 'sg2'])
    end
    it 'will return the security_groups array if security_groups is specified' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'security_groups' => ['sg3']}, infra)
      expect(infrastructure_properties.security_groups).to eq(['sg3'])
    end
    it 'will return a merged array of defaults and additional_security_groups if additional_security_groups is defined' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'additional_security_groups' => ['sg3']}, infra)
      expect(infrastructure_properties.security_groups).to eq(['sg1', 'sg2', 'sg3'])
    end
    it 'will raise an error if security_groups is not properly specified' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'security_groups' => 'sg3'}, infra)
      expect { infrastructure_properties.security_groups }.to raise_error DopCommon::PlanParsingError
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'security_groups' => [1, 2]}, infra)
      expect { infrastructure_properties.security_groups }.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an error if additional_security_groups is not properly specified' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'additional_security_groups' => 'sg3'}, infra)
      expect { infrastructure_properties.security_groups }.to raise_error DopCommon::PlanParsingError
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'additional_security_groups' => [1, 2]}, infra)
      expect { infrastructure_properties.security_groups }.to raise_error DopCommon::PlanParsingError
    end
    it 'will raise an error if both security_groups and additional_security_groups are specified' do
      infrastructure_properties = DopCommon::InfrastructureProperties.new({'additional_security_groups' => ['sg3'], 'security_groups' => ['sg3']}, infra)
      expect { infrastructure_properties.security_groups }.to raise_error DopCommon::PlanParsingError
    end
  end
end
