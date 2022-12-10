# frozen_string_literal: true

require 'mailmap'
require 'set'

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  manicmaniac/danger-mailmap
  # @tags monday, weekends, time, rattata
  #
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
