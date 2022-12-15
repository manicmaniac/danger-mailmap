# frozen_string_literal: true

describe DangerMailmap::SuggestionFormatter do
  subject(:formatter) { described_class.new(request_source, Dir.pwd) }

  let(:request_source) { double(base_branch: base_branch, head_branch: head_branch) } # rubocop:disable RSpec/VerifiedDoubles
  let(:base_branch) { 'master' }
  let(:head_branch) { 'test-danger-mailmap' }

  describe '#suggestion' do
    let(:path) { File.expand_path('.mailmap') }
    let(:emails) { [] }

    it 'outputs useful suggestion to fix warnings' do
      expect(formatter.suggestion(path, emails)).not_to be_empty
    end
  end

  describe '#mailmap_script' do
    let(:absolute_path) { File.expand_path('.mailmap') }
    let(:emails) { %w[0@example.com 1@example.com] }

    it 'outputs shell script template' do
      expect(formatter.mailmap_script(absolute_path, emails)).to eq <<~SHELL.rstrip
        echo 'Correct Name <0@example.com>' >> .mailmap
        echo 'Correct Name <1@example.com>' >> .mailmap
      SHELL
    end
  end

  describe '#filter_branch_script' do
    let(:emails) { %w[0@example.com 1@example.com] }

    it 'outputs shell script template' do
      expect(formatter.filter_branch_script(emails)).to eq <<~SHELL.rstrip
        git filter-branch --env-filter '
            if [ "$GIT_AUTHOR_EMAIL" = "0@example.com" ]; then
                GIT_AUTHOR_EMAIL="correct@example.com"
                GIT_AUTHOR_NAME="Correct Name"
            fi
            if [ "$GIT_COMMITTER_EMAIL" = "0@example.com" ]; then
                GIT_COMMITTER_EMAIL="correct@example.com"
                GIT_COMMITTER_NAME="Correct Name"
            fi
            if [ "$GIT_AUTHOR_EMAIL" = "1@example.com" ]; then
                GIT_AUTHOR_EMAIL="correct@example.com"
                GIT_AUTHOR_NAME="Correct Name"
            fi
            if [ "$GIT_COMMITTER_EMAIL" = "1@example.com" ]; then
                GIT_COMMITTER_EMAIL="correct@example.com"
                GIT_COMMITTER_NAME="Correct Name"
            fi
        ' --tag-name-filter cat master...test-danger-mailmap
      SHELL
    end

    context 'when base branch is missing' do
      let(:base_branch) { nil }

      it 'outputs nothing' do
        expect(formatter.filter_branch_script(emails)).to include '${BASE_COMMIT_HERE}'
      end
    end

    context 'when head branch is missing' do
      let(:head_branch) { nil }

      it 'outputs nothing' do
        expect(formatter.filter_branch_script(emails)).to include 'HEAD'
      end
    end
  end
end
