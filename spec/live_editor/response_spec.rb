require 'spec_helper'

RSpec.describe LiveEditor::Response do
  describe '#error?' do
    context 'with `HTTPClientError` object' do
      it 'returns `true`' do
        error_response = Net::HTTPClientError.new('1.1', 404, '')
        response = LiveEditor::Response.new(error_response)
        expect(response.error?).to eql true
      end
    end

    context 'with `HTTPServerError` object' do
      it 'returns `true`' do
        error_response = Net::HTTPServerError.new('1.1', 500, '')
        response = LiveEditor::Response.new(error_response)
        expect(response.error?).to eql true
      end
    end

    context 'with `HTTPSuccess` object' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        response = LiveEditor::Response.new(success_response)
        expect(response.error?).to eql false
      end
    end
  end

  describe '#errors' do
    context 'with JSON API-compliant validation error' do
      it 'returns an array with the error' do
        error_response = Net::HTTPUnprocessableEntity.new('1.1', 422, '')
        error_response.add_field('Content-Type', 'application/vnd.api+json')
        error_response.instance_variable_set(:@body, {
          errors: [
            { detail: "can't be blank", source: { pointer: '/data/attributes/title' }, status: '422' }
          ]
        }.to_json)
        error_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(error_response)

        expect(response.errors).to eql([{
          'detail' => "can't be blank",
          'source' => { 'pointer' => '/data/attributes/title' },
          'status' => '422'
        }])
      end
    end

    context 'with JSON validation error' do
      it 'returns an array with the error' do
        error_response = Net::HTTPUnprocessableEntity.new('1.1', 422, '')
        error_response.add_field('Content-Type', 'application/json')
        error_response.instance_variable_set(:@body, { error: 'The token has expired.' }.to_json)
        error_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(error_response)
        expect(response.errors.first['detail']).to eql "The token has expired."
      end
    end

    context 'with no error' do
      it 'returns an array with the error' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.errors).to eql []
      end
    end
  end

  describe '#json?' do
    context 'with JSON `body`' do
      it 'returns `true`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@body, { data: {} }.to_json)
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json?).to eql true
      end
    end

    context 'with no `body`' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json?).to eql false
      end
    end

    context 'with non-JSON `body`' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@body, 'bananas')
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json?).to eql false
      end
    end
  end # #json?

  describe '#json_api?' do
    context 'with JSON API `Content-Type` header and `body` content' do
      it 'returns `true`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.add_field('Content-Type', 'application/vnd.api+json')
        success_response.instance_variable_set(:@body, { data: {} }.to_json)
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json_api?).to eql true
      end
    end

    context 'with JSON API `Content-Type` header but no `body` content' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.add_field('Content-Type', 'application/vnd.api+json')
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json_api?).to eql false
      end
    end

    context 'with no `Content-Type` header but with `body` content' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@body, { data: {} }.to_json)
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json_api?).to eql false
      end
    end

    context 'with non-JSON API `Content-Type` and `body` content' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.add_field('Content-Type', 'application/json')
        success_response.instance_variable_set(:@body, { data: {} }.to_json)
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.json_api?).to eql false
      end
    end
  end # #json_api?

  describe '#parsed_body' do
    context 'with valid JSON in `body`' do
      it 'returns a valid `Hash`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@body, { data: {} }.to_json)
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.parsed_body).to be_a Hash
      end
    end

    context 'with empty `body`' do
      it 'returns a parse error' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.parsed_body).to eql LiveEditor::ParseError
      end
    end

    context 'with non-JSON `body`' do
      it 'returns a parse error' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        success_response.instance_variable_set(:@body, 'bananas')
        success_response.instance_variable_set(:@read, true)
        response = LiveEditor::Response.new(success_response)
        expect(response.parsed_body).to eql LiveEditor::ParseError
      end
    end
  end

  describe '#refreshed_oauth?' do
    context 'with `refreshed_oauth`' do
      it 'returns `true`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        response = LiveEditor::Response.new(success_response, { 'access_token' => '1234567890', 'refresh_token' => '0987654321' })
        expect(response.refreshed_oauth?).to eql true
      end
    end

    context 'with no `refreshed_oauth`' do
      it 'returns `false`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        response = LiveEditor::Response.new(success_response)
        expect(response.refreshed_oauth?).to eql false
      end
    end
  end

  describe '#success?' do
    context 'with `HTTPSuccess` object' do
      it 'returns `true`' do
        success_response = Net::HTTPSuccess.new('1.1', 200, '')
        response = LiveEditor::Response.new(success_response)
        expect(response.success?).to eql true
      end
    end

    context 'with `HTTPRedirection` object' do
      it 'returns `true`' do
        redirection_response = Net::HTTPRedirection.new('1.1', 301, '')
        response = LiveEditor::Response.new(redirection_response)
        expect(response.success?).to eql true
      end
    end

    context 'with `HTTPClientError` object' do
      it 'returns false' do
        error_response = Net::HTTPClientError.new('1.1', 404, '')
        response = LiveEditor::Response.new(error_response)
        expect(response.success?).to eql false
      end
    end
  end

  describe '#unauthorized?' do
    context 'with `HTTPUnauthorized` object' do
      it 'returns `true`' do
        unauthorized_response = Net::HTTPUnauthorized.new('1.1', 401, '')
        response = LiveEditor::Response.new(unauthorized_response)
        expect(response.unauthorized?).to eql true
      end
    end

    context 'with `HTTPSuccess` object' do
      it 'returns `true`' do
        success_response = Net::HTTPRedirection.new('1.1', 200, '')
        response = LiveEditor::Response.new(success_response)
        expect(response.unauthorized?).to eql false
      end
    end
  end
end
