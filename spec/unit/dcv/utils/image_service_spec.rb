require 'rails_helper'

describe Dcv::Utils::ImageService, type: :unit do
	describe '#for' do
		let(:known_id) { 'test:1234' }
		let(:image_service) { described_class.for(solr_doc) }
		context 'solr_doc has internet archive resources but not assets' do
			let(:archive_org_id) { '123456789' }
			let(:solr_doc) { SolrDocument.new(id: known_id, archive_org_identifier_ssi: archive_org_id) }
			it { expect(image_service).to be_a Dcv::Utils::ImageService::ArchiveOrgImages }
		end
		context 'solr_doc has no asset children' do
			let(:solr_doc) { SolrDocument.new(id: known_id, cul_number_of_members_isi: 0) }
			it { expect(image_service).to be_a Dcv::Utils::ImageService::PlaceHolderImages }
		end
		context 'solr_doc has a representative image' do
			let(:solr_doc) { SolrDocument.new(id: known_id, representative_generic_resource_pid_ssi: known_id) }
			it { expect(image_service).to be_a Dcv::Utils::ImageService::IiifImages }
		end
		context 'solr_doc has assets but no identified representative image' do
			let(:solr_doc) { SolrDocument.new(id: known_id, cul_number_of_members_isi: 1) }
			it { expect(image_service).to be_a Dcv::Utils::ImageService::IiifImages }
		end
	end
end
