# frozen_string_literal: true

module Gitlab
  class RefMatcher
    PATTERNS = {
      '*' => '.*',
      '[' => '[',
      ']' => ']',
      '^' => '^',
      '-' => '-',
    }.freeze

    def initialize(ref_name_or_pattern)
      @ref_name_or_pattern = ref_name_or_pattern
    end

    # Returns all branches/tags (among the given list of refs [`Gitlab::Git::Branch`])
    # that match the current protected ref.
    def matching(refs)
      refs.select { |ref| matches?(ref.name) }
    end

    # Checks if the protected ref matches the given ref name.
    def matches?(ref_name)
      return false if @ref_name_or_pattern.blank?

      exact_match?(ref_name) || wildcard_match?(ref_name)
    end

    # Checks if this protected ref contains a wildcard
    def wildcard?
      @ref_name_or_pattern && PATTERNS.any? do |key, _|
        @ref_name_or_pattern.include?(key)
      end
    end

    protected

    def exact_match?(ref_name)
      @ref_name_or_pattern == ref_name
    end

    def wildcard_match?(ref_name)
      return false unless wildcard?

      puts wildcard_regex
      wildcard_regex === ref_name
    end

    def wildcard_regex
      @wildcard_regex ||= begin
        quoted_name = Regexp.quote(@ref_name_or_pattern)
        regex_string = unescape_patterns(quoted_name)
        /\A#{regex_string}\z/
      end
    end

    def unescape_patterns(text)
      PATTERNS.each do |key, value|
        text = text.gsub(Regexp.quote(key), value)
      end
      text
    end
  end
end
