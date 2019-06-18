# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'

require 'gitlab/danger/roulette'

describe Gitlab::Danger::Roulette do
  class MockRoulette
    include Gitlab::Danger::Roulette
  end

  let(:teammate_data) do
    [
      {
        "username" => "in-gitlab-ce",
        "name" => "CE maintainer",
        "projects" => { "gitlab-ce" => "maintainer backend" }
      },
      {
        "username" => "in-gitlab-ee",
        "name" => "EE reviewer",
        "projects" => { "gitlab-ee" => "reviewer frontend" }
      }
    ]
  end

  before do
    allow(roulette).to receive(:roulette_data) { teammate_data }
  end

  let(:ce_teammate_matcher) do
    have_attributes(
      username: 'in-gitlab-ce',
      name: 'CE maintainer',
      projects: { 'gitlab-ce' => 'maintainer backend' })
  end

  let(:ee_teammate_matcher) do
    have_attributes(
      username: 'in-gitlab-ee',
      name: 'EE reviewer',
      projects: { 'gitlab-ee' => 'reviewer frontend' })
  end

  subject(:roulette) { MockRoulette.new }

  # We don't need to test that `http_get_json` does what it says it does - it
  # is not our code after all. Since we are propagating errors, we just need to
  # make sure we don't swallow them.
  describe '#team' do
    subject(:team) { roulette.team }

    context 'on error' do
      let(:teammate_data) do
        raise "BOOM!"
      end

      it 'propagates the error' do
        expect { team }.to raise_error(/BOOM/)
      end
    end

    context 'success' do
      it 'returns an array of teammates' do
        is_expected.to contain_exactly(ce_teammate_matcher, ee_teammate_matcher)
      end

      it 'memoizes the result' do
        expect(roulette).to receive(:roulette_data).at_most(:once)
        expect(team).to eq(roulette.team)
      end
    end
  end

  describe '#project_team' do
    subject { roulette.project_team('gitlab-ce') }

    it 'filters team by project_name' do
      is_expected.to contain_exactly(ce_teammate_matcher)
    end
  end

  describe '#spin_for_person' do
    let(:person1) { Gitlab::Danger::Teammate.new('username' => 'rymai') }
    let(:person2) { Gitlab::Danger::Teammate.new('username' => 'godfat') }
    let(:author) { Gitlab::Danger::Teammate.new('username' => 'filipa') }
    let(:ooo) { Gitlab::Danger::Teammate.new('username' => 'jacopo-beschi') }

    before do
      stub_person_message(person1, 'making GitLab magic')
      stub_person_message(person2, 'making GitLab magic')
      stub_person_message(ooo, 'OOO till 15th')
      # we don't stub Filipa, as she is the author and
      # we should not fire request checking for her

      allow(subject).to receive_message_chain(:gitlab, :mr_author).and_return(author.username)
    end

    it 'returns a random person' do
      persons = [person1, person2]
      names = persons.map(&:username)
      expect(subject).to receive(:out_of_office?)
        .exactly(:once)
        .and_call_original

      expect(spin(persons)).to have_attributes(username: be_in(names))
    end

    it 'excludes OOO persons' do
      expect(spin([ooo])).to be_nil
    end

    it 'excludes mr.author' do
      expect(subject).not_to receive(:out_of_office?)
      expect(spin([author])).to be_nil
    end

    private

    def spin(people)
      subject.spin_for_person(people, random: Random.new)
    end

    def stub_person_message(person, message)
      body = { message: message }.to_json

      WebMock
        .stub_request(:get, "https://gitlab.com/api/v4/users/#{person.username}/status")
        .to_return(body: body)
    end
  end
end
