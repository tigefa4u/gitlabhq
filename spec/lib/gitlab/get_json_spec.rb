# frozen_string_literal: true

require 'fast_spec_helper'
require 'ostruct'

require 'gitlab/get_json'

describe Gitlab::GetJSON do
  subject do
    mod = described_class
    Class.new { include mod }.new
  end

  before do
    allow(Faraday).to receive(:get) { response }
  end

  context 'the response is successful' do
    let(:response) do
      OpenStruct.new(success?: true, body: data.to_json)
    end

    let(:data) do
      {
        a: true,
        b: 3.14159,
        c: %w[one two three]
      }
    end

    it 'returns the data back to us' do
      expect(subject.http_get_json('some-url')).to eq data.transform_keys(&:to_s)
    end
  end

  context 'we cannot connect' do
    let(:response) do
      raise Faraday::ConnectionFailed, 'for some reason'
    end

    it 'raises an HTTPError' do
      expect { subject.http_get_json('url') }.to raise_error(Gitlab::GetJSON::HTTPError)
    end
  end

  context 'the response has bad JSON data' do
    let(:response) do
      OpenStruct.new(success?: true, body: 'I am not valid JSON')
    end

    it 'raises a JSONError' do
      expect { subject.http_get_json('url') }.to raise_error(Gitlab::GetJSON::JSONError)
    end
  end

  context 'the response is 404' do
    let(:response) do
      OpenStruct.new(success?: false, status: 'wibble')
    end

    it 'raises an HTTPError' do
      expect { subject.http_get_json('wobble') }.to raise_error(Gitlab::GetJSON::HTTPError)
    end

    it 'raises an error that mentions the status' do
      expect { subject.http_get_json('wobble') }.to raise_error(/wibble/)
    end
  end
end
