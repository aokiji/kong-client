# frozen_string_literal: true

extension_module = Module.new do
  def is_expected_on_call
    expect { subject }
  end
end

RSpec.configure do
  include extension_module
end
