require 'rails_helper'

describe Iiif::PresentationsController, :type => :routing do
  let(:registrant) { '10.7916' }
  let(:doi) { 'test-doi' }
  let(:collection_doi) { 'collection-doi' }
  let(:default_params) { { format: 'json', version: '3', controller: 'iiif/presentations' } }
  describe "routing" do
    context 'collection' do
      let(:collection_params) { { collection_registrant: registrant, collection_doi: collection_doi } }
      let(:action_params) { { action: 'collection' }.merge(default_params).merge(collection_params) }
      it "routes to #collection" do
        expect(:get => "/iiif/3/presentation/#{registrant}/#{collection_doi}/collection").to route_to(action_params)
      end
    end
    context "manifest" do
      let(:manifest_params) { { manifest_registrant: registrant, manifest_doi: doi } }
      let(:action_params) { { action: 'manifest' }.merge(default_params).merge(manifest_params) }
      it "routes to #manifest" do
        expect(:get => "/iiif/3/presentation/#{registrant}/#{doi}/manifest").to route_to(action_params)
      end
      context "in collection" do
        let(:manifest_params) { { manifest_registrant: registrant, manifest_doi: doi, collection_registrant: registrant, collection_doi: 'collection-doi' } }
        it "routes to #manifest" do
          expect(:get => "/iiif/3/presentation/#{registrant}/#{collection_doi}/manifest/#{registrant}/#{doi}").to route_to(action_params)
        end
      end
    end
  end
  describe "url_helpers" do
    describe "collection" do
      let(:params) { { collection_registrant: registrant, collection_doi: doi } }
      it 'produces expected public manifest paths' do
        expect(iiif_collection_path(params)).to eql("/iiif/3/presentation/#{registrant}/#{doi}/collection")
      end
    end
    describe "manifest" do
      let(:params) { { manifest_registrant: registrant, manifest_doi: doi } }
      let(:contained_params) { params.merge(collection_registrant: registrant, collection_doi: 'collection-doi') }
      it 'produces expected public manifest paths' do
        expect(iiif_manifest_path(params)).to eql("/iiif/3/presentation/#{registrant}/#{doi}/manifest")
        expect(iiif_collected_manifest_path(contained_params)).to eql("/iiif/3/presentation/#{registrant}/#{contained_params[:collection_doi]}/manifest/#{registrant}/#{doi}")
      end
    end
  end
end
