# frozen_string_literal: true

describe DangerMailmap::RequestSourcesRefinements do
  include FixtureHelper
  using described_class

  subject(:request_source) { described_class.new(ci_source, {}) }

  let(:ci_source) { double(repo_slug: '', pull_request_id: 0) } # rubocop:disable RSpec/VerifiedDoubles

  shared_examples 'temporarily adding new methods' do
    describe '#base_branch' do
      it 'returns the base branch' do
        expect(request_source.base_branch).to eq base
      end
    end

    describe '#head_branch' do
      it 'returns the head branch' do
        expect(request_source.head_branch).to eq head
      end
    end
  end

  describe Danger::RequestSources::BitbucketCloud do
    before { request_source.pr_json = JSON.parse(load_fixture('bitbucket_cloud/pr.json'), symbolize_names: true) }

    let(:base) { 'develop' }
    let(:head) { 'feature/test_danger' }

    it_behaves_like 'temporarily adding new methods'
  end

  describe Danger::RequestSources::BitbucketServer do
    before { request_source.pr_json = JSON.parse(load_fixture('bitbucket_server/pr.json'), symbolize_names: true) }

    let(:base) { 'develop' }
    let(:head) { 'feature/Danger' }

    it_behaves_like 'temporarily adding new methods'
  end

  describe Danger::RequestSources::GitHub do
    before { request_source.pr_json = JSON.parse(load_fixture('github/pr.json')) }

    let(:base) { 'master' }
    let(:head) { 'test-danger-mailmap' }

    it_behaves_like 'temporarily adding new methods'
  end

  describe Danger::RequestSources::GitLab do
    before do
      json = JSON.parse(load_fixture('gitlab/mr.json'))
      request_source.mr_json = double(json) # rubocop:disable RSpec/VerifiedDoubles
    end

    let(:base) { 'mr-test' }
    let(:head) { 'master' }

    it_behaves_like 'temporarily adding new methods'
  end

  describe Danger::RequestSources::VSTS do
    before { request_source.pr_json = JSON.parse(load_fixture('vsts/pr.json'), symbolize_names: true) }

    let(:base) { 'master' }
    let(:head) { 'feature/danger' }

    it_behaves_like 'temporarily adding new methods'
  end

  describe Danger::RequestSources::LocalOnly do
    before do
      allow(ci_source).to receive(:base_commit).and_return base
      allow(ci_source).to receive(:head_commit).and_return head
      allow(request_source.scm).to receive(:exec).and_return '0'
    end

    let(:base) { 'base' }
    let(:head) { 'head' }

    it_behaves_like 'temporarily adding new methods'
  end
end
