# frozen_string_literal: true

require 'mailmap'
require 'set'

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
    #
    def check(path = '.mailmap')
      mailmap = Mailmap::Map.load(path)
      commits_by_emails
        .reject { |email, _| allowed_patterns_include?(email) || mailmap.include_email?(email) }
        .each do |email, commits|
          revisions = commits.map(&:sha).join(', ')
          warn("#{email} is not included in mailmap (#{revisions})")
        end
    end

    private

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
  end
end
