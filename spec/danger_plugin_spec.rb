# frozen_string_literal: true

describe Danger::DangerMailmap do # rubocop:disable RSpec/FilePath
  include DangerPluginHelper
  include FixtureHelper

  define :be_a_hash_containing_exactly do |expected|
    match do |actual|
      expect(actual).to be_kind_of(Hash).and have_attributes(size: expected.size).and include expected
    end
  end

  let(:dangerfile) { testing_dangerfile }
  let(:mailmap) { dangerfile.mailmap }

  # Commits extracted from a real pull request.
  # @see https://github.com/manicmaniac/danger-mailmap/pull/9
  let(:commits) do
    YAML.safe_load(
      load_fixture('git_commits.yml'),
      aliases: true,
      permitted_classes: [Time] + classes_in(Git, Git::Object)
    )
  end

  before do
    # @see https://github.com/manicmaniac/danger-mailmap/pull/9
    pr_json = load_fixture('github_pr.json')
    allow(mailmap.github).to receive(:pr_json).and_return pr_json
    allow(mailmap.git).to receive(:commits).and_return commits
  end

  it 'is a plugin' do
    expect(described_class.new(nil)).to be_a Danger::Plugin
  end

  describe '#check' do
    let(:mailmap_file) { Tempfile.new('mailmap') }
    let(:mailmap_contents) { '' }

    before do
      mailmap_file.write(mailmap_contents)
      mailmap_file.close
    end

    after { mailmap_file.unlink }

    context 'when .mailmap does not exist' do
      it 'raises Errno::ENOENT' do
        expect { mailmap.check('/path/to/nothing') }.to raise_error Errno::ENOENT
      end
    end

    context 'when commits include both known authors and unknown authors' do
      let(:mailmap_contents) { 'Correct <correct@example.com>' }

      it 'warns only about unknown commits' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report).to be_a_hash_containing_exactly(
          errors: [],
          markdowns: [],
          messages: [],
          warnings: [
            "wrong@example.com is not included in mailmap (#{commits[0].sha}, #{commits[1].sha}, #{commits[2].sha})"
          ]
        )
      end
    end

    context 'when commits include only known authors' do
      let(:mailmap_contents) { "Correct <correct@example.com>\nWrong <wrong@example.com>" }

      it 'warns nothing' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report).to be_a_hash_containing_exactly(
          errors: [],
          markdowns: [],
          messages: [],
          warnings: []
        )
      end
    end

    context 'when an email matches allowed_patterns' do
      before { mailmap.allowed_patterns = [/correct@.+/, 'wrong@example.com'] }

      it 'warns nothing' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report).to be_a_hash_containing_exactly(
          errors: [],
          markdowns: [],
          messages: [],
          warnings: []
        )
      end
    end
  end

  describe '#commits_by_emails' do
    it 'aggregates commits by author emails and committer emails' do
      expect(mailmap.send(:commits_by_emails)).to be_a_hash_containing_exactly(
        'correct@example.com' => an_instance_of(Set) & contain_exactly(
          *commits[1..3].map { |commit| an_object_having_attributes(sha: commit.sha) }
        ),
        'wrong@example.com' => an_instance_of(Set) & contain_exactly(
          *commits[0..2].map { |commit| an_object_having_attributes(sha: commit.sha) }
        )
      )
    end
  end
end
