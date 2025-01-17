# frozen_string_literal: true

RSpec.describe_current do
  subject(:result) { described_class.new }

  it { expect(result).to be_success }

  context 'when we fail' do
    before { result.failure! }

    it { expect(result).not_to be_success }
  end

  context 'when we fail and succeed' do
    before do
      result.failure!
      result.success!
    end

    it { expect(result).to be_success }
  end
end
