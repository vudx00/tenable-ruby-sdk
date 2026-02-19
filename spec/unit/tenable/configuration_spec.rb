# frozen_string_literal: true

RSpec.describe Tenable::Configuration do
  subject(:config) { described_class.new(**params) }

  let(:params) { { access_key: 'direct_access', secret_key: 'direct_secret' } }

  # Helper to temporarily set ENV vars and guarantee cleanup
  def with_env(vars)
    original = vars.each_key.to_h { |k| [k, ENV.fetch(k, nil)] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    original.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe 'credential resolution' do
    it 'uses direct params when provided' do
      expect(config.access_key).to eq('direct_access')
      expect(config.secret_key).to eq('direct_secret')
    end

    it 'prefers direct params over env vars' do
      with_env('TENABLE_ACCESS_KEY' => 'env_access', 'TENABLE_SECRET_KEY' => 'env_secret') do
        cfg = described_class.new(access_key: 'direct_access', secret_key: 'direct_secret')
        expect(cfg.access_key).to eq('direct_access')
        expect(cfg.secret_key).to eq('direct_secret')
      end
    end

    it 'reads from ENV when no direct params given' do
      with_env('TENABLE_ACCESS_KEY' => 'env_access', 'TENABLE_SECRET_KEY' => 'env_secret') do
        cfg = described_class.new
        expect(cfg.access_key).to eq('env_access')
        expect(cfg.secret_key).to eq('env_secret')
      end
    end
  end

  describe 'defaults' do
    it 'sets base_url to https://cloud.tenable.com' do
      expect(config.base_url).to eq('https://cloud.tenable.com')
    end

    it 'sets timeout to 30' do
      expect(config.timeout).to eq(30)
    end

    it 'sets open_timeout to 10' do
      expect(config.open_timeout).to eq(10)
    end

    it 'sets max_retries to 3' do
      expect(config.max_retries).to eq(3)
    end
  end

  describe 'validation' do
    context 'when access_key is empty' do
      let(:params) { { access_key: '', secret_key: 'secret' } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /access_key/i)
      end
    end

    context 'when access_key is nil and not in ENV' do
      let(:params) { { secret_key: 'secret' } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /access_key/i)
      end
    end

    context 'when secret_key is empty' do
      let(:params) { { access_key: 'access', secret_key: '' } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /secret_key/i)
      end
    end

    context 'when secret_key is nil and not in ENV' do
      let(:params) { { access_key: 'access' } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /secret_key/i)
      end
    end

    context 'when base_url is not HTTPS' do
      let(:params) { { access_key: 'access', secret_key: 'secret', base_url: 'http://cloud.tenable.com' } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /https/i)
      end
    end

    context 'when timeout is not positive' do
      let(:params) { { access_key: 'access', secret_key: 'secret', timeout: 0 } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /timeout/i)
      end
    end

    context 'when timeout is negative' do
      let(:params) { { access_key: 'access', secret_key: 'secret', timeout: -5 } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /timeout/i)
      end
    end

    context 'when open_timeout is not positive' do
      let(:params) { { access_key: 'access', secret_key: 'secret', open_timeout: 0 } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /open_timeout/i)
      end
    end

    context 'when max_retries is negative' do
      let(:params) { { access_key: 'access', secret_key: 'secret', max_retries: -1 } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /max_retries/i)
      end
    end

    context 'when max_retries exceeds 10' do
      let(:params) { { access_key: 'access', secret_key: 'secret', max_retries: 11 } }

      it 'raises an ArgumentError' do
        expect { config }.to raise_error(ArgumentError, /max_retries/i)
      end
    end

    context 'when max_retries is 0' do
      let(:params) { { access_key: 'access', secret_key: 'secret', max_retries: 0 } }

      it 'does not raise an error' do
        expect { config }.not_to raise_error
      end
    end

    context 'when max_retries is 10' do
      let(:params) { { access_key: 'access', secret_key: 'secret', max_retries: 10 } }

      it 'does not raise an error' do
        expect { config }.not_to raise_error
      end
    end
  end

  describe 'immutability' do
    it 'is frozen after creation' do
      expect(config).to be_frozen
    end

    it 'cannot modify attributes after creation' do
      expect { config.instance_variable_set(:@access_key, 'hacked') }.to raise_error(FrozenError)
    end
  end
end
