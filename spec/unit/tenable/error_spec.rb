# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Error do
  it 'is a subclass of StandardError' do
    expect(described_class).to be < StandardError
  end

  it 'accepts a custom message' do
    error = described_class.new('something went wrong')
    expect(error.message).to eq('something went wrong')
  end

  it 'has a default message' do
    error = described_class.new
    expect(error.message).not_to be_empty
  end
end

RSpec.describe Tenable::AuthenticationError do
  it 'is a subclass of Tenable::Error' do
    expect(described_class).to be < Tenable::Error
  end

  it 'has an actionable default message' do
    error = described_class.new
    expect(error.message).to match(/authenticat|credential|api.key|access/i)
  end

  it 'does not include API keys in the default message' do
    error = described_class.new
    expect(error.message).not_to match(/accessKey|secretKey/i)
  end
end

RSpec.describe Tenable::ApiError do
  it 'is a subclass of Tenable::Error' do
    expect(described_class).to be < Tenable::Error
  end

  it 'stores the status_code' do
    error = described_class.new(status_code: 404, body: 'Not Found')
    expect(error.status_code).to eq(404)
  end

  it 'stores the body' do
    error = described_class.new(status_code: 500, body: '{"error":"internal"}')
    expect(error.body).to eq('{"error":"internal"}')
  end

  it 'includes the status code in the message' do
    error = described_class.new(status_code: 422, body: 'Unprocessable')
    expect(error.message).to include('422')
  end

  it 'includes the body in the message' do
    error = described_class.new(status_code: 400, body: 'Bad Request')
    expect(error.message).to include('Bad Request')
  end

  it 'does not include API keys in the default message' do
    error = described_class.new(status_code: 401, body: 'Unauthorized')
    expect(error.message).not_to match(/accessKey|secretKey/i)
  end
end

RSpec.describe Tenable::RateLimitError do
  it 'is a subclass of Tenable::ApiError' do
    expect(described_class).to be < Tenable::ApiError
  end

  it 'has an actionable default message referencing rate limiting' do
    error = described_class.new(status_code: 429, body: 'Too Many Requests')
    expect(error.message).to match(/rate.limit|too.many.requests|retry|throttl/i)
  end
end

RSpec.describe Tenable::ConnectionError do
  it 'is a subclass of Tenable::Error' do
    expect(described_class).to be < Tenable::Error
  end

  it 'has an actionable default message' do
    error = described_class.new
    expect(error.message).to match(/connect|network|reach|host/i)
  end

  it 'does not include API keys in the default message' do
    error = described_class.new
    expect(error.message).not_to match(/accessKey|secretKey/i)
  end
end

RSpec.describe Tenable::TimeoutError do
  it 'is a subclass of Tenable::Error' do
    expect(described_class).to be < Tenable::Error
  end

  it 'has an actionable default message' do
    error = described_class.new
    expect(error.message).to match(/timeout|timed?.out|deadline|too.long/i)
  end
end

RSpec.describe Tenable::ParseError do
  it 'is a subclass of Tenable::Error' do
    expect(described_class).to be < Tenable::Error
  end

  it 'has an actionable default message' do
    error = described_class.new
    expect(error.message).to match(/pars|json|response|unexpected|format/i)
  end

  it 'does not include API keys in the default message' do
    error = described_class.new
    expect(error.message).not_to match(/accessKey|secretKey/i)
  end
end
