# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/glci/failure_analyzer'
require_relative '../../../../../tooling/lib/tooling/glci/failure_categories/download_job_trace'
require_relative '../../../../../tooling/lib/tooling/glci/failure_categories/job_trace_to_failure_category'
require_relative '../../../../../tooling/lib/tooling/glci/failure_categories/report_job_failure'

RSpec.describe Tooling::Glci::FailureAnalyzer, feature_category: :tooling do
  let(:job_id)           { '12345' }
  let(:trace_path)       { 'path/to/trace.log' }
  let(:failure_category) { 'test_failures' }

  let(:download_instance)    { instance_double(Tooling::Glci::FailureCategories::DownloadJobTrace) }
  let(:categorizer_instance) { instance_double(Tooling::Glci::FailureCategories::JobTraceToFailureCategory) }
  let(:reporter_instance)    { instance_double(Tooling::Glci::FailureCategories::ReportJobFailure) }

  subject(:analyzer) { described_class.new }

  before do
    allow(Tooling::Glci::FailureCategories::DownloadJobTrace).to receive(:new).and_return(download_instance)
    allow(Tooling::Glci::FailureCategories::JobTraceToFailureCategory).to receive(:new).and_return(categorizer_instance)
    allow(Tooling::Glci::FailureCategories::ReportJobFailure).to receive(:new).and_return(reporter_instance)

    allow(download_instance).to receive(:download).and_return(trace_path)
    allow(categorizer_instance).to receive(:process).with(trace_path).and_return(failure_category)
    allow(reporter_instance).to receive(:report)
  end

  describe '#analyze_job' do
    context 'when no trace could be downloaded' do
      let(:trace_path) { nil }

      it 'displays an error message' do
        result = ""

        expect do
          result = analyzer.analyze_job(job_id)
        end.to output("[GCLI Failure Analyzer] Missing job trace. Exiting.\n").to_stderr

        expect(Tooling::Glci::FailureCategories::JobTraceToFailureCategory).not_to have_received(:new)
        expect(Tooling::Glci::FailureCategories::ReportJobFailure).not_to have_received(:new)

        expect(result).to be_nil
      end
    end

    context 'when no failure category could be found' do
      let(:failure_category) { nil }

      it 'displays an error message' do
        result = ""

        expect do
          result = analyzer.analyze_job(job_id)
        end.to output("[GCLI Failure Analyzer] Missing failure category. Exiting.\n").to_stderr

        expect(Tooling::Glci::FailureCategories::ReportJobFailure).not_to have_received(:new)
        expect(result).to be_nil
      end
    end

    it 'creates a DownloadJobTrace instance' do
      analyzer.analyze_job(job_id)

      expect(Tooling::Glci::FailureCategories::DownloadJobTrace).to have_received(:new)
    end

    it 'calls download on the DownloadJobTrace instance' do
      analyzer.analyze_job(job_id)

      expect(download_instance).to have_received(:download)
    end

    it 'creates a JobTraceToFailureCategory instance' do
      analyzer.analyze_job(job_id)

      expect(Tooling::Glci::FailureCategories::JobTraceToFailureCategory).to have_received(:new)
    end

    it 'calls process on the JobTraceToFailureCategory instance with the trace path' do
      analyzer.analyze_job(job_id)

      expect(categorizer_instance).to have_received(:process).with(trace_path)
    end

    it 'creates a ReportJobFailure instance with job_id and failure_category' do
      analyzer.analyze_job(job_id)

      expect(Tooling::Glci::FailureCategories::ReportJobFailure).to have_received(:new).with(
        job_id: job_id,
        failure_category: failure_category
      )
    end

    it 'calls report on the ReportJobFailure instance' do
      analyzer.analyze_job(job_id)

      expect(reporter_instance).to have_received(:report)
    end

    it 'follows the correct sequence of operations' do
      analyzer.analyze_job(job_id)

      expect(download_instance).to have_received(:download).ordered
      expect(categorizer_instance).to have_received(:process).ordered
      expect(reporter_instance).to have_received(:report).ordered
    end

    it 'returns the failure category' do
      expect(analyzer.analyze_job(job_id)).to eq(failure_category)
    end

    context 'when an error occurs in any component' do
      before do
        allow(download_instance).to receive(:download).and_raise(RuntimeError, 'Download failed')
      end

      it 'allows the error to propagate' do
        expect { analyzer.analyze_job(job_id) }.to raise_error(RuntimeError, 'Download failed')
      end
    end
  end
end
