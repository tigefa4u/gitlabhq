# frozen_string_literal: true

shared_examples 'cluster application allowed to uninstall true' do |application_name|
  describe '#allowed_to_uninstall?' do
    subject { create(application_name).allowed_to_uninstall? }

    it { is_expected.to be_truthy }
  end
end
