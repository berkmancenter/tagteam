RSpec.shared_context 'interactions' do
  let(:outcome) { described_class.run(inputs) }
  let(:outcome!) { described_class.run!(inputs) }
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:valid_result) { instance_double(ActiveInteraction::Base, valid?: true) }
  let(:invalid_result) do
    instance_double(
      ActiveInteraction::Base,
      valid?: false,
      errors: instance_double(ActiveInteraction::Errors, messages: {})
    )
  end
end

RSpec.shared_examples_for 'an interaction' do
  context 'without required inputs' do
    let(:inputs) { {} }

    it 'is invalid' do
      expect(outcome).to be_invalid
    end
  end

  context 'with required inputs' do
    it 'is valid' do
      expect(outcome).to be_valid
    end
  end
end
