# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

task default: :spec

desc 'Run all linters'
task lint: %I[rubocop lint_docs]

desc 'Ensure that the plugin passes `danger plugins lint`'
task :lint_docs do
  sh 'danger plugins lint'
end

desc 'Create Git commits on the current branch for testing purpose'
task :add_test_commits do
  raise 'Git working tree is not clean.' unless `git status --porcelain`.rstrip.empty?

  correct = ['Correct Name', 'correct@example.com']
  wrong = ['Wrong Name', 'wrong@example.com']
  [correct, wrong].repeated_permutation(2).each do |(a_name, a_email), (c_name, c_email)|
    env = {
      'GIT_AUTHOR_NAME' => a_name,
      'GIT_AUTHOR_EMAIL' => a_email,
      'GIT_COMMITTER_NAME' => c_name,
      'GIT_COMMITTER_EMAIL' => c_email
    }
    sh(env, 'git', 'commit', '-m' "author: #{a_email}, committer: #{c_email}", '--allow-empty')
  end
end
