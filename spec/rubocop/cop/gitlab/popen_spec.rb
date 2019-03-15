# frozen_string_literal: true
require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/popen'

describe RuboCop::Cop::Gitlab::Popen do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when popen3 is called as a module method of Open3' do
    let(:source) do
      <<~SRC
      Open3.popen3({}, *%W[pwd]) do |stdin, stdout, stderr, wait_thr|
        stdin.puts(1)
        [stdout.read, stderr.read, wait_thr.value]
      end
      SRC
    end

    it 'registers an offence' do
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
    end
  end

  context 'when popen3 is called after the class has extended with Open3' do
    let(:source) do
      <<~SRC
      popen3({}, *%W[pwd]) do |stdin, stdout, stderr, wait_thr|
        stdin.puts(1)
        [stdout.read, stderr.read, wait_thr.value]
      end
      SRC
    end

    it 'registers an offence' do
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
    end
  end
end
