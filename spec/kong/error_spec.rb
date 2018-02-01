# frozen_string_literal: true

require 'spec_helper'
require 'kong/error'

RSpec.describe Kong::Error do
  subject { described_class.new(status, message) }

  let(:message) { 'Failure' }
  let(:status) { 200 }

  it { is_expected.to be_a(StandardError) }
  it { is_expected.to have_attributes(status: status, message: message) }
end
