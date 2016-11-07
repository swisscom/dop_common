require 'spec_helper'

#
# This test does not run on ruby 1.8.7 because of the mixlib-shellout gem
# and is therefor deactivated for now.
#

describe 'dop-puppet-autosign' do

  before :each do
    @tmpdir = '/tmp/dop-puppet-autosign-test'
    @plan_store = DopCommon::PlanStore.new(@tmpdir)
  end

  after :each do
    FileUtils.remove_entry_secure(@tmpdir)
  end

  let(:plan) { 'spec/fixtures/simple_plan.yaml' }

  context 'There is no plan with the node in the plan store' do
    command 'dop-puppet-autosign --plan_cache /tmp/dop-puppet-autosign-test linux01.example.com', :allow_error => true
    its(:exitstatus) { is_expected.to_not eq 0 }
  end
  context 'The node is in one of the plans in the plan store' do
    before do
      @plan_store.add(plan)
    end
    command 'dop-puppet-autosign --plan_cache /tmp/dop-puppet-autosign-test linux01.example.com'
    its(:exitstatus) { is_expected.to eq 0 }
  end
end

