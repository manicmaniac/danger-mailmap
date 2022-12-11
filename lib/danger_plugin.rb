# frozen_string_literal: true

require 'mailmap'
require 'set'
require 'shellwords'

module Danger
  # A Danger plugin to check if .mailmap has a canonical name of author and committer.
  #
  # @example Check all commits in the pull request against the top-level .mailmap.
  #
  #          mailmap.check
  #
  # @example Check against mailmap file in custom location with ignoring some users.
  #
  #          mailmap.allowed_patterns = [
  #            /.+@(users\.noreply\.)?github\.com/,
  #            'good@example.com'
  #          ]
  #          mailmap.check '/path/to/mailmap'
  #
  # @see  manicmaniac/danger-mailmap
  # @tags git, mailmap
  class DangerMailmap < Plugin
    # Regular expression patterns of email where `danger-mailmap` does not warn like allow-list.
    # If a string is set, it is considered as fixed pattern.
    # @return [Array<String, Regexp>]
    attr_accessor :allowed_patterns

    # Check whether if an author of each commits has proper email.
    #
    # @param [String] path Path to .mailmap file (default $GIT_WORK_TREE/.mailmap).
    # @return [void]
    def check(path = nil)
      path = path ? File.expand_path(path) : File.join(git_working_dir, '.mailmap')
      mailmap = Mailmap::Map.load(path)
      commits_by_emails = commits_by_unknown_emails(mailmap)
      return if commits_by_emails.empty?

      commits_by_emails.each { |email, commits| warn(format_warning(path, email, commits)) }
      markdown(suggestion(path, commits_by_emails.keys))
    end

    private

    HOW_TO_FIX_URL = 'https://github.com/manicmaniac/danger-mailmap#how-to-fix'
    private_constant :HOW_TO_FIX_URL

    def format_warning(path, email, commits)
      revisions = commits.map(&:sha).join(', ')
      "`#{email}` is not included in #{link_to(path)} (#{revisions})"
    end

    def git_working_dir
      @git_working_dir ||= Dir.chdir(env.scm.folder) do
        env.scm.exec('rev-parse --show-toplevel')
      end
    end

    def git_relative_path(path)
      Pathname.new(path).relative_path_from(git_working_dir).to_s
    end

    def link_to(path)
      relative_path = git_relative_path(path)
      scm_plugin = @dangerfile.respond_to?(danger.scm_provider) ? @dangerfile.public_send(danger.scm_provider) : nil
      method_name = %i[markdown_link html_link].detect { |name| scm_plugin.respond_to?(name) }
      method_name ? scm_plugin.public_send(method_name, relative_path, full_path: false) : relative_path
    end

    def commits_by_unknown_emails(mailmap)
      commits_by_emails.reject { |email, _| allowed_patterns_include?(email) || mailmap.include_email?(email) }
    end

    def commits_by_emails
      commits_by_emails = Hash.new do |hash, key|
        hash[key] = Set.new
      end
      git.commits.each do |commit|
        commits_by_emails[commit.author.email] << commit
        commits_by_emails[commit.committer.email] << commit
      end
      commits_by_emails
    end

    def allowed_patterns_include?(email)
      allowed_patterns&.any? do |pattern|
        if pattern.is_a?(Regexp)
          email =~ pattern
        else
          email == pattern
        end
      end
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
      base = github.pr_json['base']['ref']
      head = github.pr_json['head']['ref']
      script = +"git filter-branch --env-filter '\n"
      emails.each do |email|
        script << <<~SHELL
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
  end
end
