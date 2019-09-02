# frozen_string_literal: true

shared_examples 'cluster application core specs' do |application_name|
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  describe '#can_uninstall?' do
    it 'calls allowed_to_uninstall?' do
      expect(subject).to receive(:allowed_to_uninstall?).and_return(true)

      expect(subject.can_uninstall?).to be_truthy
    end

    context 'when neither scheduled or installed' do
      before do
        expect(subject.scheduled?).to be_falsey
        expect(subject.uninstalling?).to be_falsey
      end

      it { expect(subject.can_uninstall?).to be_truthy }
    end

    context 'when scheduled or uninstalling' do
      it 'returns false if scheduled' do
        application = create(application_name, :scheduled)
        expect(application.can_uninstall?).to be_falsey
      end

      it 'returns false if uninstalling' do
        application = create(application_name, :uninstalling)
        expect(application.can_uninstall?).to be_falsey
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
