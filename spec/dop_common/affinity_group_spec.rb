require 'spec_helper'

describe DopCommon::AffinityGroup do

  describe '#positive' do
    it "will return 'true' if the affinity group is positive and 'false' if it is not" do
      affinity_group = DopCommon::AffinityGroup.new('ag', {'positive' => true, 'enforce' => true, 'cluster' => 'cl'})
      expect(affinity_group.positive).to eq(true)
      affinity_group = DopCommon::AffinityGroup.new('ag', {'positive' => false, 'enforce' => true, 'cluster' => 'cl'})
      expect(affinity_group.positive).to eq(false)
    end
    it 'will raise an error if the flag is not specified correctly' do
      affinity_group = DopCommon::AffinityGroup.new('ag', {})
      expect { affinity_group.positive }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#enforce' do
    it "will return 'true' if the affinity group should be enforced and 'false' if it shouldn't" do
      affinity_group = DopCommon::AffinityGroup.new('ag', {'positive' => true, 'enforce' => true, 'cluster' => 'cl'})
      expect(affinity_group.enforce).to eq(true)
      affinity_group = DopCommon::AffinityGroup.new('ag', {'positive' => false, 'enforce' => false, 'cluster' => 'cl'})
      expect(affinity_group.enforce).to eq(false)
    end
    it 'will raise an error if the flag is not specified correctly' do
      affinity_group = DopCommon::AffinityGroup.new('ag', {})
      expect { affinity_group.enforce }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#cluster' do
    it 'will return the cluster name of the affinity group' do
      affinity_group = DopCommon::AffinityGroup.new('ag', {'positive' => true, 'enforce' => true, 'cluster' => 'cl'})
      expect(affinity_group.cluster).to eq('cl')
    end
    it 'will raise an error in case of invalid cluster specification' do
      affinity_group = DopCommon::AffinityGroup.new('ag', {})
      expect { affinity_group.cluster }.to raise_error DopCommon::PlanParsingError
    end
  end
end
