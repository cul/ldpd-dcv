require 'rails_helper'

describe Iiif::Authz::V2::Bytestreams, type: :unit do
  let(:test_class) do
    Class.new(ApplicationController) do
      include Iiif::Authz::V2::Bytestreams
    end
  end
  subject(:controller) do
    test_class.new
  end
  describe '#has_probeable_resource?' do
    let(:bytestream_id) { 'content' }
    let(:params) { { bytestream_id: bytestream_id } }

    before do
      allow(controller).to receive(:params).and_return(params)      
    end

    it 'returns false when passed nil' do
      expect(controller.has_probeable_resource?(nil)).to be false
    end

    context 'has a SolrDocument' do
      let(:solr_doc) { instance_double(SolrDocument) }
      let(:resource_doc) { { id: "fedora/pid/#{bytestream_id}" } }

      context 'with resources' do
        before do
          allow(controller).to receive(:resources_for_document).with(solr_doc, false).and_return([resource_doc])
        end

        it 'works when #resources_for_document returns a present value' do
          expect(controller.has_probeable_resource?(solr_doc)).to be true
        end
      end

      context 'without resources' do
        let(:dc_type) { 'Software' }

        before do
          allow(solr_doc).to receive(:fetch).with('dc_type_ssm', []).and_return([dc_type])
          allow(controller).to receive(:resources_for_document).with(solr_doc, false).and_return([])
        end

        it 'returns false' do
          expect(controller.has_probeable_resource?(solr_doc)).to be false
        end

        context 'but an image dc type' do
          let(:dc_type) { 'StillImage' }
          
          it 'returns true' do
            expect(controller.has_probeable_resource?(solr_doc)).to be true
          end
        end
      end
    end
  end  
end
