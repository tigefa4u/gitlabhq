# frozen_string_literal: true

shared_examples 'cluster application core specs' do |application_name|
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  describe '#can_uninstall?' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(application).to receive(:allowed_to_uninstall?).and_return(allowed_to_uninstall_result)
    end

    let(:application) { build(application_name, status) }
    let(:status) { status_name }

    context "when allowed_to_uninstall? is true" do
      let(:allowed_to_uninstall_result) { true }

      where(:expected_value, :status_name) do
        true  | :uninstall_errored
        true  | :installed
        false | :scheduled
        false | :uninstalling
      end

      with_them do
        it { expect(application.can_uninstall?).to eq expected_value }
      end
    end

    context "when allowed_to_uninstall is false" do
      let(:allowed_to_uninstall_result) { false }

      where(:expected_value, :status_name) do
        false | :uninstall_errored
        false | :installed
        false | :scheduled
        false | :uninstalling
      end

      with_them do
        it { expect(application.can_uninstall?).to eq expected_value }
      end
    end
  end

  describe '#name' do
    it 'is .application_name' do
      expect(subject.name).to eq(described_class.application_name)
    end

    it 'is recorded in Clusters::Cluster::APPLICATIONS' do
      expect(Clusters::Cluster::APPLICATIONS[subject.name]).to eq(described_class)
    end
  end
end
