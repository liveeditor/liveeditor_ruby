require 'spec_helper'

RSpec.describe LiveEditor do
  describe '.client' do
    it 'returns configured client' do
      client = LiveEditor::Client.new
      LiveEditor::client = client
      expect(LiveEditor::client).to eql client
    end
  end

  describe '.include_query_string_for' do
    context 'with `nil` argument' do
      it 'returns empty string' do
        expect(LiveEditor::include_query_string_for(nil)).to eql ''
      end
    end

    context 'with string argument' do
      it 'returns query string containing string' do
        expect(LiveEditor::include_query_string_for('theme')).to eql 'include=theme'
      end
    end

    context 'with array of strings as argument' do
      it 'returns query string containing comma-delimited list' do
        expect(LiveEditor::include_query_string_for(['draft', 'draft.user'])).to eql 'include=draft,draft.user'
      end
    end
  end
end
