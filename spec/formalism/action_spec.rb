# frozen_string_literal: true

describe Formalism::Action do
	def initialize_test_action
		test_action_class.new(params)
	end

	subject(:test_action) { initialize_test_action }

	let(:test_action_class) do
		Class.new(described_class) do
			private

			def execute
				params[:string].upcase
			end
		end
	end

	let(:params) { { string: 'foo' } }

	describe '#params' do
		subject { test_action.params }

		it { is_expected.to eq params }
		it { is_expected.not_to be params }

		context 'without received params' do
			let(:params) { nil }

			it { is_expected.to eq({}) }
		end
	end

	shared_examples 'run' do
		context 'with correct value' do
			it { is_expected.to eq 'FOO' }
		end

		context 'with incorrect value' do
			let(:params) { { string: 42 } }

			it do
				expect { subject }.to raise_error(
					NoMethodError, /undefined method `upcase' for 42:Integer/
				)
			end
		end
	end

	describe '#run' do
		subject { test_action.run }

		include_examples 'run'
	end

	describe '.run' do
		subject { test_action_class.run(params) }

		include_examples 'run'
	end

	describe '#==' do
		subject { test_action == initialize_test_action }

		it { is_expected.to be true }
	end
end
