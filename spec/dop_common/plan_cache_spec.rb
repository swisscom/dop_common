require 'spec_helper'

describe DopCommon::PlanCache do

  before :each do
    @tmpdir = Dir.mktmpdir
    @plan_store = DopCommon::PlanStore.new(@tmpdir)
    @plan_cache = DopCommon::PlanCache.new(@plan_store)
    @plan_store.add(plan)
  end

  after :each do
    FileUtils.remove_entry_secure(@tmpdir)
  end

  let(:plan) { 'spec/fixtures/simple_plan.yaml' }
  let(:plan_name) { 'simple_plan' }
  let(:plan_dir) { File.join(@tmpdir, plan_name) }
  let(:versions_dir) { File.join(plan_dir, 'versions') }
  let(:node_name) { 'linux01.example.com' }

  describe '#plan_by_node' do
    before :each do
      @original_plan = @plan_cache.plan_by_node(node_name)
    end
    subject { @plan_cache.plan_by_node(node_name) }

    context 'The plan in the store is unchanged' do
      it { is_expected.to be_a(DopCommon::Plan) }
      it { is_expected.to equal(@original_plan) }
    end
    context 'The plan in the store was updated' do
      before do
        @plan_store.update(plan)
      end
      it { is_expected.to be_a(DopCommon::Plan) }
      it { is_expected.to_not equal(@original_plan) }
    end
    context 'There is no plan with this node' do
      let(:node_name) { 'nonexisting.example.com' }
      it { is_expected.to be(nil) }
    end
  end

end

