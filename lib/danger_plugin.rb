# frozen_string_literal: true

require 'danger_mailmap/request_sources_refinements'
require 'danger_mailmap/suggestion_formatter'
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

    # If `true`, `danger-mailmap` will add suggestion comments to a pull request (`true` by default).
    # @return [Boolean]
    attr_accessor :show_suggestion

    def initialize(*args)
      super(*args)
      self.show_suggestion = true
    end

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
      markdown(suggestion(path, commits_by_emails.keys)) if show_suggestion
    end

    private

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
      formatter = ::DangerMailmap::SuggestionFormatter.new(env.request_source, git_working_dir)
      formatter.suggestion(path, emails)
    end
  end
end
