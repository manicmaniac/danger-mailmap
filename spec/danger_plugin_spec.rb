# frozen_string_literal: true

describe Danger::DangerMailmap do
  let(:dangerfile) { testing_dangerfile }
  let(:mailmap) { dangerfile.mailmap }

  before do
    # example json: `curl -o github_pr.json https://api.github.com/repos/danger/danger-plugin-template/pulls/18`
    json = File.read("#{__dir__}/support/fixtures/github_pr.json")
    allow(mailmap.github).to receive(:pr_json).and_return(json)
  end

  it 'is a plugin' do
    expect(described_class.new(nil)).to be_a Danger::Plugin
  end

  describe '#check' do
    context 'when .mailmap does not exist' do
      it 'does nothing' do
        mailmap.check
      end
    end
  end
end
