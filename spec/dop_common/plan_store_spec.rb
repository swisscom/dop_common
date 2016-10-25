require 'spec_helper'

describe DopCommon::PlanStore do

  before :each do
    @tmpdir = Dir.mktmpdir
    @plan_store = DopCommon::PlanStore.new(@tmpdir)
  end

  after :each do
    FileUtils.remove_entry_secure(@tmpdir)
  end

  let(:plan) { 'spec/fixtures/simple_plan.yaml' }
  let(:plan_name) { 'simple_plan' }
  let(:plan_dir) { File.join(@tmpdir, plan_name) }
  let(:versions_dir) { File.join(plan_dir, 'versions') }

  describe '#add' do
    subject { @plan_store.add(plan) }

    context 'The plan file is correct' do
      it { is_expected.to eq('simple_plan') }
      it { subject; expect(Dir[versions_dir + '/*.yaml'].length).to be 1 }
    end
    context 'The plan is in hash form' do
      let(:plan) { YAML.load_file('spec/fixtures/simple_plan.yaml') }
      it { is_expected.to eq('simple_plan') }
      it { subject; expect(Dir[versions_dir + '/*.yaml'].length).to be 1 }
    end
    context 'The plan is invalid' do
      let(:plan) { 'spec/fixtures/simple_plan_invalid.yaml' }
      it { expect{subject}.to raise_error StandardError }
    end
    context 'The plan was already added' do
      before { @plan_store.add(plan) }
      it { expect{subject}.to raise_error StandardError }
    end
    context 'A node is already present' do
      before { @plan_store.add('spec/fixtures/other_plan_same_nodes.yaml') }
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#update' do
    before do |example|
      @plan_store.add(plan) unless example.metadata[:skip_before]
    end
    subject { @plan_store.update(plan) }

    context 'The plan file is correct' do
      it { is_expected.to eq('simple_plan') }
      it { subject; expect(Dir[versions_dir + '/*.yaml'].length).to be 2 }
    end
    context 'The plan is in hash form' do
      let(:plan) { YAML.load_file('spec/fixtures/simple_plan.yaml') }
      it { is_expected.to eq('simple_plan') }
      it { subject; expect(Dir[versions_dir + '/*.yaml'].length).to be 2 }
    end
    context 'The plan is invalid' do
      let(:invalid_plan) { 'spec/fixtures/simple_plan_invalid.yaml' }
      subject { @plan_store.update(invalid_plan) }
      it { expect{subject}.to raise_error StandardError }
    end
    context 'The plan was not already added', :skip_before => true do
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#remove' do
    before { @plan_store.add(plan) }
    subject { @plan_store.remove(plan_name) }

    context 'plan exists' do
      it { is_expected.to eq('simple_plan') }
      it { subject; expect(File.exists?(plan_dir)).to be false }
    end
    context 'plan does not exist' do
      let(:plan_name) { 'not_existing_plan' }
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#list' do
    before { @plan_store.add(plan) }
    subject { @plan_store.list }

    context 'one plan is in the store' do
      it { is_expected.to be_an Array }
      it { is_expected.to have_exactly(1).items }
      it { is_expected.to include plan_name }
    end
  end

  describe '#show_versions' do
    before do |example|
      @plan_store.add(plan) unless example.metadata[:skip_before]
    end
    subject { @plan_store.show_versions(plan_name) }

    context 'the plan is in the store' do
      it { is_expected.to be_an Array }
      it { is_expected.to have_exactly(1).items }
    end
    context 'the plan is not in the store', :skip_before => true do
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#get_plan_hash' do
    before do |example|
      @plan_store.add(plan) unless example.metadata[:skip_before]
    end
    subject { @plan_store.get_plan_hash(plan_name) }

    context 'the plan is in the store' do
      it { is_expected.to be_a Hash }
      it { is_expected.to have_key 'name' }
    end
    context 'the plan is not in the store', :skip_before => true do
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#get_plan_hash_diff' do
    before do |example|
      unless example.metadata[:skip_before]
        @plan_store.add(plan)
        @plan_store.update('spec/fixtures/simple_plan_modified.yaml')
      end
    end
    let(:old_version) { @plan_store.show_versions(plan_name).first }
    subject { @plan_store.get_plan_hash_diff(plan_name, old_version) }

    context 'the plan is in the store' do
      it { is_expected.to be_an Array }
    end
    context 'the plan is not in the store', :skip_before => true do
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#get_plan' do
    before do |example|
      @plan_store.add(plan) unless example.metadata[:skip_before]
    end
    subject { @plan_store.get_plan(plan_name) }

    context 'the plan is in the store' do
      it { is_expected.to be_a DopCommon::Plan }
      it { expect(subject.name).to eq(plan_name) }
    end
    context 'the plan is not in the store', :skip_before => true do
      it { expect{subject}.to raise_error StandardError }
    end
  end

  describe '#run_lock' do
    pending
  end

  describe '#run_lock?' do
    pending
  end

  describe '#state_store' do
    pending
  end

end

