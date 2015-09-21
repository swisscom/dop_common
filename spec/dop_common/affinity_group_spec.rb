require 'spec_helper'

describe DopCommon::AffinityGroup do

  before :all do
    DopCommon.log.level = ::Logger::ERROR
  end

  describe '#positive' do
    it "will return 'true' if the affinity group is positive and 'false' if it is not" do
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'enforce' => true, 'cluster' => 'cl1' })
      expect(affinity_group.positive).to eq(true)
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => false, 'enforce' => true, 'cluster' => 'cl1' })
      expect(affinity_group.positive).to eq(false)
    end
    it 'will raise an error if the flag is not specified correctly' do
      # The positive flag is absent in the specification of affinity group
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'enforce' => true, 'cluster' => 'cl1' })
      expect { affinity_group.positive }.to raise_error DopCommon::PlanParsingError
      # The positive flag is of wrong type
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => 'invalid', 'enforce' => true, 'cluster' => 'cl1' })
      expect { affinity_group.positive }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#enforce' do
    it "will return 'true' if the affinity group should be enforced and 'false' if it shouldn't" do
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'enforce' => true, 'cluster' => 'cl1' })
      expect(affinity_group.enforce).to eq(true)
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => false, 'enforce' => false, 'cluster' => 'cl1' })
      expect(affinity_group.enforce).to eq(false)
    end
    it 'will raise an error if the flag is not specified correctly' do
      # The enforced flag is absent in the specification of affinity group
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'cluster' => 'cl1' })
      expect { affinity_group.enforce }.to raise_error DopCommon::PlanParsingError
      # The enforced flag is of wrong type
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'enforce' => 'invalid', 'cluster' => 'cl1' })
      expect { affinity_group.enforce }.to raise_error DopCommon::PlanParsingError
    end
  end

  describe '#cluster' do
    it 'will return the cluster name of the affinity group' do
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'enforce' => true, 'cluster' => 'cl1' })
      expect(affinity_group.cluster).to eq('cl1')
    end
    it 'will raise an error in case of invalid cluster specification' do
      # The cluster identifier is absent in the specification of affinity group
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'enforce' => true })
      expect { affinity_group.cluster }.to raise_error DopCommon::PlanParsingError
      # The cluster identifier is not a string
      affinity_group = DopCommon::AffinityGroup.new('ag1', { 'positive' => true, 'enforce' => true, 'cluster' => {:invalid => 'invalid'} })
      expect { affinity_group.cluster }.to raise_error DopCommon::PlanParsingError
    end
  end
end
