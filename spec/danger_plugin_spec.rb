# frozen_string_literal: true

describe Danger::DangerMailmap do # rubocop:disable RSpec/SpecFilePathFormat
  include DangerPluginHelper
  include FixtureHelper

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
    pr_json = JSON.parse(load_fixture('github/pr.json'))
    allow(mailmap.github).to receive(:pr_json).and_return pr_json
    allow(mailmap.env.request_source).to receive(:pr_json).and_return pr_json
    allow(mailmap.git).to receive(:commits).and_return commits
    git_repo = instance_double(Danger::GitRepo)
    allow(git_repo).to receive(:folder).and_return project_root_path.to_s
    allow(git_repo).to receive(:exec)
      .with('rev-parse --show-toplevel')
      .and_return project_root_path.to_s
    allow(git_repo).to receive(:exec)
      .with(a_string_starting_with('diff --no-index'))
      .and_return ''
    allow(mailmap.env).to receive(:scm).and_return git_repo
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

      before do
        formatter = instance_double(DangerMailmap::SuggestionFormatter, suggestion: 'suggestion')
        allow(DangerMailmap::SuggestionFormatter).to receive(:new).and_return formatter
      end

      it 'does not show errors' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:errors]).to be_empty
      end

      it 'shows suggestion' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:markdowns]).to match_array(having_attributes(message: 'suggestion'))
      end

      it 'does not show messages' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:messages]).to be_empty
      end

      it 'warns only about unknown commits' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:warnings]).to match_array(
          a_string_starting_with('`wrong@example.com`')
            .and(ending_with("#{commits[0].sha}, #{commits[1].sha}, #{commits[2].sha})"))
        )
      end

      context 'with show_suggestion = nil' do
        before { mailmap.show_suggestion = false }

        it 'does not show errors' do
          mailmap.check(mailmap_file.path)
          expect(dangerfile.status_report[:errors]).to be_empty
        end

        it 'does not show suggestion' do
          mailmap.check(mailmap_file.path)
          expect(dangerfile.status_report[:markdowns]).to be_empty
        end

        it 'does not show messages' do
          mailmap.check(mailmap_file.path)
          expect(dangerfile.status_report[:messages]).to be_empty
        end

        it 'shows a warning' do
          mailmap.check(mailmap_file.path)
          expect(dangerfile.status_report[:warnings]).to match_array(a_kind_of(String))
        end
      end
    end

    context 'when commits include only known authors' do
      let(:mailmap_contents) { "Correct <correct@example.com>\nWrong <wrong@example.com>" }

      it 'does not show errors' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:errors]).to be_empty
      end

      it 'does not show suggestion' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:markdowns]).to be_empty
      end

      it 'does not show messages' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:messages]).to be_empty
      end

      it 'does not show warnings' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:warnings]).to be_empty
      end
    end

    context 'when an email matches allowed_patterns' do
      before { mailmap.allowed_patterns = [/correct@.+/, 'wrong@example.com'] }

      it 'does not show errors' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:errors]).to be_empty
      end

      it 'does not show suggestion' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:markdowns]).to be_empty
      end

      it 'does not show messages' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:messages]).to be_empty
      end

      it 'does not show warnings' do
        mailmap.check(mailmap_file.path)
        expect(dangerfile.status_report[:warnings]).to be_empty
      end
    end
  end

  describe '#commits_by_emails' do
    it 'aggregates commits by author emails and committer emails' do
      commit_shas = commits.map(&:sha)
      commit_by_emails = mailmap.send(:commits_by_emails)
      aggregate_failures do
        expect(commit_by_emails).to be_a(Hash)
        expect(commit_by_emails.keys).to eq %w[wrong@example.com correct@example.com]
        expect(commit_by_emails.values).to all(be_a(Set))
        expect(commit_by_emails['correct@example.com'].map(&:sha)).to eq commit_shas[1..3]
        expect(commit_by_emails['wrong@example.com'].map(&:sha)).to eq commit_shas[0..2]
      end
    end
  end
end
