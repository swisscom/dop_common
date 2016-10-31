require 'spec_helper'

describe DopCommon::Utils::DataSize do
  describe '#size' do
    {
      1000     => 1000,
      '1000K'  => 1000*1024,
      '512M'   => 512*1024*1024,
      '1000G'  => 1000*1024*1024*1024,
      '1KB'    => 1000,
      '1000MB' => 1000*1000*1000,
      '2500GB' => 2500*1000*1000*1000,
    }.each do |k, v|
      it 'will return size in bytes if specified properly' do
        size = DopCommon::Utils::DataSize.new(k)
        expect(size).to be_an_instance_of(DopCommon::Utils::DataSize)
        expect(size.bytes).to eq v
      end
    end
    [nil, [], 2.4, '2500m', '1000'].each do |input|
      it 'will raise an exception if not specified properly' do
        size = DopCommon::Utils::DataSize.new(input)
        expect{size.bytes}.to raise_error DopCommon::PlanParsingError
      end
    end
  end
end
