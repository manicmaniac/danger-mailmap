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
    sh(env, 'git', 'commit', '-m', "author: #{a_email}, committer: #{c_email}", '--allow-empty')
  end
end

downloadable_fixtures = {
  'spec/support/fixtures/bitbucket_cloud/pr.json' =>
    'https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/bitbucket_cloud_api/pr_response.json',
  'spec/support/fixtures/bitbucket_server/pr.json' =>
    'https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/bitbucket_server_api/pr_response.json',
  'spec/support/fixtures/github/pr.json' =>
    'https://api.github.com/repos/manicmaniac/danger-mailmap/pulls/9',
  'spec/support/fixtures/gitlab/mr.json' =>
    'https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/gitlab_api/merge_request_1_response.json',
  'spec/support/fixtures/vsts/pr.json' =>
    'https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/vsts_api/pr_response.json'
}

downloadable_fixtures.each do |path, url|
  file path do |task|
    require 'json'
    require 'open-uri'

    text = URI.parse(url).open.read
    # Remove unwanted HTTP headers in JSON files from danger/danger.
    text = text.slice(/{.+/m)
    File.write(task.name, JSON.pretty_generate(JSON.parse(text)))
  end
end

file 'spec/support/fixtures/git_commits.yml' => ['spec/support/fixtures/github/pr.json'] do |task|
  require 'git'
  require 'yaml'

  json = YAML.safe_load(File.read(task.source))
  base = json.dig('base', 'sha')
  head = json.dig('head', 'sha')
  commits = Git.open(__dir__).log.between(base, head).entries
  # Mask working directory and remove trailing spaces.
  yaml = commits.to_yaml.gsub(__dir__, '/tmp/danger-mailmap').gsub(/ +$/, '')
  File.write(task.name, yaml)
end

namespace :fixtures do
  desc 'Generate test fixtures'
  multitask generate: ['spec/support/fixtures/git_commits.yml', *downloadable_fixtures.keys]
end
