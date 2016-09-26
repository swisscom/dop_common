require 'spec_helper'
require 'byebug'

describe DopCommon::DataDisk do
  before(:all) do
    @infrastructures = {
      'rhev' => DopCommon::Infrastructure.new('rhev', {
        'type' => 'rhev'
      }),
      'rhos' => DopCommon::Infrastructure.new('rhos', {
        'type' => 'rhos'
      }),
      'baremetal' => DopCommon::Infrastructure.new('baremetal', {
        'type' => 'baremetal'
      }),
      'vsphere' => DopCommon::Infrastructure.new('vsphere', {
        'type' => 'vsphere'
      }),
    }
  end

  describe '#pool' do
    %w(rhev vsphere rhos baremetal).each do |provider|
      properties = case provider
        when 'rhos'; { 'tenant' => 'foo' }
        when 'baremetal'; {}
        else { 'datacenter' => 'foo', 'cluster' => 'bar' }
      end
      it "will return pool's name if specified properly for provider #{provider}" do
        data_disk = DopCommon::DataDisk.new('foo',
          { 'pool' => 'foo' },
          {
            :parsed_infrastructure => @infrastructures[provider],
            :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
              properties,
              @infrastructures[provider]
            )
          }
        )
        expect(data_disk.pool).to eq 'foo'
      end
      it "will return default pool's if specified properly for provider #{provider} " do
        data_disk = DopCommon::DataDisk.new('foo', {},
          {
            :parsed_infrastructure => @infrastructures[provider],
            :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
              properties.merge('default_pool' => 'bar'),
              @infrastructures[provider]
            )
          }
        )
        expect(data_disk.pool).to eq 'bar'
      end
      it %w(rhos baremetal).include?(provider) ?
        "will return nil if unspecified because it is optional for provider #{provider}" :
        "will raise an error if unspecified because it is required for provider #{provider}" do
          data_disk = DopCommon::DataDisk.new('foo', {},
            {
              :parsed_infrastructure => @infrastructures[provider],
              :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
                properties,
                @infrastructures[provider]
              )
            }
          )
          %w(rhos baremetal).include?(provider) ?
            (expect(data_disk.pool).to eq nil) :
            (expect{data_disk.pool}.to raise_error DopCommon::PlanParsingError)
      end
      [[], {}, :invalid, 2].each do |pool_val|
        it "will raise an error if not specified properly" do
          data_disk = DopCommon::DataDisk.new('foo',
            { 'pool' => pool_val},
            {
              :parsed_infrastructure => @infrastructures[provider],
              :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
                properties,
                @infrastructures[provider]
              )
            }
          )
          expect{data_disk.pool}.to raise_error DopCommon::PlanParsingError
        end
      end
    end
  end

  describe '#size' do
    [1024*1024, "#{1024*124}k", "1024m", "100G"].each do |size_val|
      it 'will return size in bytes if specified properly' do
        data_disk = DopCommon::DataDisk.new('foo',
          { 'size' => size_val },
          {
            :parsed_infrastructure => @infrastructures['baremetal'],
            :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
              {},
              @infrastructures['baremetal']
            )
          }
        )
        expect(data_disk.size).to be_kind_of(Fixnum)
        expect(data_disk.size).to eq(data_disk.send(:to_bytes, size_val))
      end
    end
    [nil, [], {}, :'256m', :'256'].each do |size_val|
      it 'will return size in bytes if specified properly' do
        data_disk = DopCommon::DataDisk.new('foo',
          { 'size' => size_val },
          {
            :parsed_infrastructure => @infrastructures['baremetal'],
            :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
              {},
              @infrastructures['baremetal']
            )
          }
        )
        expect{data_disk.size}.to raise_error DopCommon::PlanParsingError
      end
    end
  end

  describe '#thin?' do
    it 'will return true if not explicitly defined' do
      data_disk = DopCommon::DataDisk.new('foo',
        {},
        {
          :parsed_infrastructure => @infrastructures['baremetal'],
          :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
            {},
            @infrastructures['baremetal']
          )
        }
      )
      expect(data_disk.thin?).to be true
    end
    [true, false].each do |thin_val|
      it 'will return true or false if specified properly' do
        data_disk = DopCommon::DataDisk.new('foo',
          { 'thin' => thin_val },
          {
            :parsed_infrastructure => @infrastructures['baremetal'],
            :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
              {},
              @infrastructures['baremetal']
            )
          }
        )
        expect(data_disk.thin?).to be thin_val
      end
    end
  end
  ['true', 'false', nil, [], {}, :true, :false].each do |thin_val|
      it "will raise an error if isn't specified properly" do
        data_disk = DopCommon::DataDisk.new('foo',
          { 'thin' => thin_val },
          {
            :parsed_infrastructure => @infrastructures['baremetal'],
            :parsed_infrastructure_properties => DopCommon::InfrastructureProperties.new(
              {},
              @infrastructures['baremetal']
            )
          }
        )
        expect{data_disk.thin?}.to raise_error DopCommon::PlanParsingError
      end
    end
end
