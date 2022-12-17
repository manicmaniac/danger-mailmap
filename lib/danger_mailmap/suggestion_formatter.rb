# frozen_string_literal: true

require 'danger_mailmap/request_sources_refinements'
require 'pathname'

module DangerMailmap
  # A class to format suggestion to fix warnings.
  class SuggestionFormatter
    using ::DangerMailmap::RequestSourcesRefinements

    HOW_TO_FIX_URL = 'https://github.com/manicmaniac/danger-mailmap#how-to-fix'
    private_constant :HOW_TO_FIX_URL

    def initialize(request_source, git_working_dir)
      @request_source = request_source
      @git_working_dir = git_working_dir
    end

    def suggestion(path, emails)
      <<~MARKDOWN
        <blockquote>
        <details><summary>If it is the first time for you to contribute to this repository, add your name and email to mailmap.</summary>

        ```sh
        #{mailmap_script(path, emails)}
        ```

        </details>

        <details><summary>If you want to use another name and email, rewrite commits and push them.</summary>

        ```sh
        #{filter_branch_script(emails)}
        ```

        </details>

        <details><summary>If you did not tell your name and email to Git, configure Git.</summary>

        ```sh
        git config --global user.email 'correct@example.com'
        git config --global user.name 'Correct Name'
        ```

        </details>

        Visit [#{HOW_TO_FIX_URL}](#{HOW_TO_FIX_URL}) for more information.
        </blockquote>
      MARKDOWN
    end

    def mailmap_script(path, emails)
      path = git_relative_path(path)
      emails.map { |email| "echo 'Correct Name <#{email}>' >> #{path}" }.join("\n")
    end

    def filter_branch_script(emails) # rubocop:disable Metrics/MethodLength
      base = @request_source.base_branch || '"${BASE_COMMIT_HERE}"'
      head = @request_source.head_branch || 'HEAD'
      script = +"git filter-branch --env-filter '\n"
      emails.each do |email|
        script << indent(4, <<~SHELL)
          if [ "$GIT_AUTHOR_EMAIL" = "#{email}" ]; then
              GIT_AUTHOR_EMAIL="correct@example.com"
              GIT_AUTHOR_NAME="Correct Name"
          fi
          if [ "$GIT_COMMITTER_EMAIL" = "#{email}" ]; then
              GIT_COMMITTER_EMAIL="correct@example.com"
              GIT_COMMITTER_NAME="Correct Name"
          fi
        SHELL
      end
      script << "' --tag-name-filter cat #{base}...#{head}"
    end

    private

    def git_relative_path(path)
      Pathname.new(path).relative_path_from(@git_working_dir).to_s
    end

    def indent(size, string)
      string.lines.map { |line| (' ' * size) + line }.join
    end
  end
end
