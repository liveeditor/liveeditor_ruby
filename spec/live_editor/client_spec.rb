require 'spec_helper'

RSpec.describe LiveEditor::Client do
  let(:client) { LiveEditor::Client.new(domain: 'example.liveeditorapp.com', access_token: '1234567890', refresh_token: '0987654321') }

  before do
    # Config client.
    LiveEditor::client = client

    # Auto-refresh of OAuth token when first try to an endpoint returns
    # unauthorized.
    stub_request(:post, 'http://auth.api.liveeditorapp.com/oauth/token.json')
      .to_return(status: 200, body: { access_token: '0987654321', refresh_token: '1234567890' }.to_json)
  end

  describe '#get' do
    let(:response) { client.get('/layouts', :cms) }

    let(:payload) do
      {
        'type' => 'layouts',
        'id' => '4f254a03-71eb-49fb-a389-ed5e7f2d9c9f',
        'data' => {}
      }
    end

    context 'with successful response' do
      before do
        # First call to endpoint is successful.
        stub_request(:get, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 200, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql true
      end

      it 'returns HTTP OK response' do
        expect(response.response).to be_a Net::HTTPOK
      end
    end # with successful response

    context 'with successful response after auto-refreshing access token' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:get, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is successful.
        stub_request(:get, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 200, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql true
      end

      it 'returns HTTP Created response' do
        expect(response.response).to be_a Net::HTTPOK
      end
    end # with successful response after auto-refreshing access token

    context 'with unauthorized response' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:get, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is also unsuccessful.
        stub_request(:get, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is error' do
        expect(response.error?).to eql true
      end

      it 'is JSON' do
        expect(response.json?).to eql true
      end

      it 'has the error' do
        expect(response.errors).to eql [{ 'detail' => 'Unauthorized request' }]
      end

      it 'returns HTTP Unauthorized response' do
        expect(response.response).to be_a Net::HTTPUnauthorized
      end
    end # with unauthorized response

    context 'with not found response' do
      before do
        stub_request(:get, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 404, body: payload.to_json)
      end

      it 'returns HTTP Not Found response' do
        response = client.get('/layouts', :cms)
        expect(response.response).to be_a Net::HTTPNotFound
      end
    end

    context 'with no configured client' do
      let(:client) { LiveEditor::Client.new }

      it 'raises an exception' do
        expect { response }.to raise_error NoMethodError
      end
    end
  end # #get

  describe '#post' do
    let(:payload) do
      {
        data: {
          type: 'layouts',
          attributes: {
            title: 'My Layout',
            content: '<!DOCTYPE html>'
          }
        }
      }
    end

    let(:response) { client.post('/layouts', :cms, payload: payload) }

    context 'with successful response' do
      before do
        # First call to endpoint is successful.
        stub_request(:post, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 201, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql true
      end

      it 'returns HTTP Created response' do
        expect(response.response).to be_a Net::HTTPCreated
      end
    end # with successful response

    context 'with successful response after auto-refreshing access token' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:post, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is successful.
        stub_request(:post, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 201, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql true
      end

      it 'returns HTTP Created response' do
        expect(response.response).to be_a Net::HTTPCreated
      end
    end # with successful response after auto-refreshing access token

    context 'with unauthorized response' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:post, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is also unsuccessful.
        stub_request(:post, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is error' do
        expect(response.error?).to eql true
      end

      it 'is JSON' do
        expect(response.json?).to eql true
      end

      it 'has the error' do
        expect(response.errors).to eql [{ 'detail' => 'Unauthorized request' }]
      end

      it 'returns HTTP Unauthorized response' do
        expect(response.response).to be_a Net::HTTPUnauthorized
      end
    end # with unauthorized response

    context 'with not found response' do
      before do
        stub_request(:post, 'http://example.cms.api.liveeditorapp.com/layouts')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 404, body: payload.to_json)
      end

      it 'returns HTTP Not Found response' do
        response = client.post('/layouts', :cms, payload: payload)
        expect(response.response).to be_a Net::HTTPNotFound
      end
    end

    context 'with no configured client' do
      let(:client) { LiveEditor::Client.new }

      it 'raises an exception' do
        expect { response }.to raise_error NoMethodError
      end
    end
  end # #post

  describe '#patch' do
    let(:payload) do
      {
        data: {
          type: 'regions',
          id: '1',
          attributes: {
            title: 'Header',
            var_name: 'header'
          }
        }
      }
    end

    let(:response) { client.patch('/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f', :cms, payload: payload) }

    context 'with successful response' do
      before do
        # First call to endpoint is successful.
        stub_request(:patch, 'http://example.cms.api.liveeditorapp.com/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 200, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql true
      end

      it 'returns HTTP OK response' do
        expect(response.response).to be_a Net::HTTPOK
      end
    end # with successful response

    context 'with successful response after auto-refreshing access token' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:patch, 'http://example.cms.api.liveeditorapp.com/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is successful.
        stub_request(:patch, 'http://example.cms.api.liveeditorapp.com/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 200, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql true
      end

      it 'returns HTTP OK response' do
        expect(response.response).to be_a Net::HTTPOK
      end
    end # with successful response after auto-refreshing access token

    context 'with unauthorized response' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:patch, 'http://example.cms.api.liveeditorapp.com/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is also unsuccessful.
        stub_request(:patch, 'http://example.cms.api.liveeditorapp.com/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is error' do
        expect(response.error?).to eql true
      end

      it 'is JSON' do
        expect(response.json?).to eql true
      end

      it 'has the error' do
        expect(response.errors).to eql [{ 'detail' => 'Unauthorized request' }]
      end

      it 'returns HTTP Unauthorized response' do
        expect(response.response).to be_a Net::HTTPUnauthorized
      end
    end # with unauthorized response

    context 'with not found response' do
      before do
        stub_request(:patch, 'http://example.cms.api.liveeditorapp.com/regions/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(body: payload.to_json, headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 404, body: payload.to_json)
      end

      it 'returns HTTP Not Found response' do
        expect(response.response).to be_a Net::HTTPNotFound
      end
    end

    context 'with no configured client' do
      let(:client) { LiveEditor::Client.new }

      it 'raises an exception' do
        expect { response }.to raise_error NoMethodError
      end
    end
  end # #patch

  describe '#delete' do
    let(:response) { client.delete('/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f', :cms) }

    context 'with successful response' do
      before do
        # First call to endpoint is successful.
        stub_request(:delete, 'http://example.cms.api.liveeditorapp.com/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 204, headers: { 'Content-Type': 'application/vnd.api+json'})
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql false
      end

      it 'returns HTTP OK response' do
        expect(response.response).to be_a Net::HTTPNoContent
      end
    end # with successful response

    context 'with successful response after auto-refreshing access token' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:delete, 'http://example.cms.api.liveeditorapp.com/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is successful.
        stub_request(:delete, 'http://example.cms.api.liveeditorapp.com/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 204, headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'is JSON API' do
        expect(response.json_api?).to eql false
      end

      it 'returns HTTP Created response' do
        expect(response.response).to be_a Net::HTTPNoContent
      end
    end # with successful response after auto-refreshing access token

    context 'with unauthorized response' do
      before do
        # First call to endpoint is unsuccessful.
        stub_request(:delete, 'http://example.cms.api.liveeditorapp.com/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)

        # Second call to endpoint is also unsuccessful.
        stub_request(:delete, 'http://example.cms.api.liveeditorapp.com/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(headers: { 'Authorization': 'Bearer 0987654321' })
          .to_return(status: 401, headers: { 'Content-Type': 'application/json' }, body: { error: 'Unauthorized request' }.to_json)
      end

      it 'returns a `LiveEditor::API::Response`' do
        expect(response.is_a?(LiveEditor::Response)).to eql true
      end

      it 'is error' do
        expect(response.error?).to eql true
      end

      it 'is JSON' do
        expect(response.json?).to eql true
      end

      it 'has the error' do
        expect(response.errors).to eql [{ 'detail' => 'Unauthorized request' }]
      end

      it 'returns HTTP Unauthorized response' do
        expect(response.response).to be_a Net::HTTPUnauthorized
      end
    end # with unauthorized response

    context 'with not found response' do
      before do
        stub_request(:delete, 'http://example.cms.api.liveeditorapp.com/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f')
          .with(headers: { 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 404)
      end

      it 'returns HTTP Not Found response' do
        response = client.delete('/layouts/4f254a03-71eb-49fb-a389-ed5e7f2d9c9f', :cms)
        expect(response.response).to be_a Net::HTTPNotFound
      end
    end

    context 'with no configured client' do
      let(:client) { LiveEditor::Client.new }

      it 'raises an exception' do
        expect { response }.to raise_error NoMethodError
      end
    end
  end # #delete
end
