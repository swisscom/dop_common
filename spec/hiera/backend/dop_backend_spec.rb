require 'spec_helper'
require 'hiera'
require 'hiera/backend/dop_backend'

describe Hiera::Backend::Dop_backend do

  before :each do
    @tmpdir = Dir.mktmpdir
    @plan_store = DopCommon::PlanStore.new(@tmpdir)
    @plan_cache = DopCommon::PlanCache.new(@plan_store)
    @plan_store.add(plan)
    config = YAML.load_file(hiera_conf)
    config.merge!({:dop => {:plan_store_dir => @tmpdir}})
    @hiera = Hiera.new(:config => config)
  end

  after :each do
    FileUtils.remove_entry_secure(@tmpdir)
  end

  let(:hiera_conf) { 'spec/fixtures/hiera/hiera.yaml' }
  let(:plan) { 'spec/fixtures/simple_plan.yaml' }
  let(:plan_name) { 'simple_plan' }
  let(:plan_dir) { File.join(@tmpdir, plan_name) }
  let(:versions_dir) { File.join(plan_dir, 'versions') }
  let(:node_name) { 'linux01.example.com' }
  let(:var) { 'somevar' }
  let(:scope) { {'::clientcert' => node_name} }

  describe '#lookup' do
    subject { @hiera.lookup(var, nil, scope) }

    context 'There is a plan in the store with the data' do
      it { is_expected.to eq('someval') }
    end

    #context 'val is not set in the plan' do
    #  let(:var) { 'someothervar' }
    #  it { is_expected.to be(nil) }
    #end

  end

end

