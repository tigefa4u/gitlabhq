#!/usr/bin/env ruby

# Change test file pattern to match only feature specs for branches ending with "-frontend"
class KnapsackFilePattern
  def run
    frontend_branch = ENV['CI_COMMIT_REF_NAME'] =~ /-frontend(-ee)?$/

    if ENV['CI_PROJECT_NAMESPACE'] == 'gitlab-org' && frontend_branch
      warn 'Running only feature specs for frontend branch...'
      puts 'spec/features/**{,/*/**}/*_spec.rb'
    else
      puts 'spec/**{,/*/**}/*_spec.rb'
    end
  end
end

KnapsackFilePattern.new.run
