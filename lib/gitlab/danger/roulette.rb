# frozen_string_literal: true

require 'cgi'

require_dependency 'gitlab/get_json'
require_dependency 'gitlab/danger/teammate'

# To use this module, you need to implement a `roulette_data :: Array<Hash>` method, which
# returns the data needed to play reviewer roulette.
#
# For an example of this, see: `danger/plugins/roulette.rb`
module Gitlab
  module Danger
    module Roulette
      include ::Gitlab::GetJSON
      # Looks up the current list of GitLab team members and parses it into a
      # useful form
      #
      # @return [Array<Teammate>]
      def team
        @team ||= roulette_data.map { |hash| ::Gitlab::Danger::Teammate.new(hash) }
      end

      # Like +team+, but only returns teammates in the current project, based on
      # project_name.
      #
      # @return [Array<Teammate>]
      def project_team(project_name)
        team.select { |member| member.in_project?(project_name) }
      end

      def canonical_branch_name(branch_name)
        branch_name.gsub(/^[ce]e-|-[ce]e$/, '')
      end

      def new_random(seed)
        Random.new(Digest::MD5.hexdigest(seed).to_i(16))
      end

      # Known issue: If someone is rejected due to OOO, and then becomes not OOO, the
      # selection will change on next spin
      def spin_for_person(people, random:)
        people.shuffle(random: random)
          .find(&method(:valid_person?))
      end

      private

      def valid_person?(person)
        !mr_author?(person) && !out_of_office?(person)
      end

      def mr_author?(person)
        person.username == gitlab.mr_author
      end

      def out_of_office?(person)
        username = CGI.escape(person.username)
        api_endpoint = "https://gitlab.com/api/v4/users/#{username}/status"
        response = http_get_json(api_endpoint)
        response["message"]&.match?(/OOO/i)
      rescue Gitlab::GetJSON::Error
        false # this is no worse than not checking for OOO
      end
    end
  end
end
