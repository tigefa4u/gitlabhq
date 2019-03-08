module RspecProfilingExt
  module Git
    def branch
      if ENV['CI_COMMIT_REF_NAME']
        "#{defined?(Gitlab::License) ? 'ee' : 'ce'}:#{ENV['CI_COMMIT_REF_NAME']}"
      else
        super
      end
    end
  end

  module Run
    def example_finished(*args)
      super
    rescue => err
      return if @already_logged_example_finished_error # rubocop:disable Gitlab/ModuleWithInstanceVariables

      $stderr.puts "rspec_profiling couldn't collect an example: #{err}. Further warnings suppressed."
      @already_logged_example_finished_error = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    alias_method :example_passed, :example_finished
    alias_method :example_failed, :example_finished
  end
end

if Rails.env.test?
  RspecProfiling.configure do |config|
    if ENV.key?('CI')
      RspecProfiling::VCS::Git.prepend(RspecProfilingExt::Git)
      RspecProfiling::Run.prepend(RspecProfilingExt::Run)
      config.collector = RspecProfiling::Collectors::CSV
      config.csv_path = -> { "rspec_profiling/#{Time.now.to_i}-#{SecureRandom.hex(8)}-rspec-data.csv" }
    end
  end
end
