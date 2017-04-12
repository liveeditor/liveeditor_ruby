require 'spec_helper'
require 'securerandom'

RSpec.describe LiveEditor::CMS::Revision do
  let(:client) do
    LiveEditor::Client.new(domain: 'example.liveeditorapp.com', access_token: '1234567890', refresh_token: '0987654321')
  end

  let(:revision_id) { SecureRandom.uuid }
  let(:version_id)  { SecureRandom.uuid }
  let(:page_id)     { SecureRandom.uuid }

  before { LiveEditor::client = client }

  describe '.find' do
    context 'with no includes' do
      let(:payload) do
        {
          'data' => {
            'type' => 'revisions',
            'id' => revision_id,
            'attributes' => {
              'comments' => nil,
              'status' => 'pending',
              'versions-count' => 1,
              'created-at' => Time.now.to_json
            }
          }
        }
      end

      let(:response) { LiveEditor::CMS::Revision.find(revision_id) }

      before do
        stub_request(:get, "http://example.cms.api.liveeditorapp.com/revisions/#{revision_id}")
          .with(headers: { 'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 200, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'returns HTTP OK response' do
        expect(response.response).to be_a Net::HTTPOK
      end

      it 'returns the expected response payload' do
        expect(response.parsed_body).to eql payload
      end
    end # with no includes

    context 'with included versions' do
      let(:payload) do
        {
          'data' => {
            'type' => 'revisions',
            'id' => revision_id,
            'attributes' => {
              'comments' => nil,
              'status' => 'pending',
              'versions-count' => 1,
              'created-at' => Time.now.to_json
            }
          },
          'included' => [
            {
              'type' => 'versions',
              'id' => version_id,
              'attributes' => {
                'event' => 'update',
                'object-changes' => {
                  'path' => [
                    '/donuts_and_pastries',
                    '/donuts-and-pastries'
                  ]
                },
                'created-at' => Time.now.to_json
              },
              'relationships' => {
                'item' => {
                  'data' => {
                    'type' => 'pages',
                    'id' => page_id
                  }
                }
              }
            }
          ]
        }
      end

      let(:response) do
        LiveEditor::CMS::Revision.find(revision_id, include: 'versions')
      end

      before do
        stub_request(:get, "http://example.cms.api.liveeditorapp.com/revisions/#{revision_id}?include=versions")
          .with(headers: { 'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer 1234567890' })
          .to_return(status: 200, headers: { 'Content-Type': 'application/vnd.api+json'}, body: payload.to_json)
      end

      it 'is successful' do
        expect(response.success?).to eql true
      end

      it 'returns HTTP OK response' do
        expect(response.response).to be_a Net::HTTPOK
      end

      it 'returns the expected response payload' do
        expect(response.parsed_body).to eql payload
      end
    end
  end # .find
end
