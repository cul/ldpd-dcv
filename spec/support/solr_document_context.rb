shared_context "a solr document", shared_context: :metadata do
	let(:document_id) { 'document_id' }
	let(:types) { ['Unknown'] }
	let(:restrictions) { [] }
	let(:slugs) { [] }
	let(:slug) { slugs.first}
	let(:archive_org_id) { nil }
	let(:active_fedora_model) { nil }
	let(:sources) { [] }
	let(:dois) { [] }
	let(:context_urls) { nil }
	let(:related_urls) { nil }
	let(:title_displays) { ["Display Title"] }
	let(:solr_data) {  {
			id: document_id, dc_type_ssm: types, source_ssim: sources, restriction_ssim: restrictions,
			slug_ssim: slugs, ezid_doi_ssim: dois, lib_item_in_context_url_ssm: context_urls,
			lib_non_item_in_context_url_ssm: related_urls, archive_org_identifier_ssi: archive_org_id,
			title_display_ssm: title_displays, active_fedora_model_ssi: active_fedora_model
		}
	 }
	let(:solr_document) { SolrDocument.new(solr_data) }
end

shared_context "indexed from a site object", shared_context: :metadata do
	let(:types) { ['Publish Target'] }
	let(:slugs) { ['slug'] }
end

shared_context "indexed with restrictions", shared_context: :metadata do
	let(:restrictions) { ['Some Restriction'] }
end

shared_context "indexed with a doi", shared_context: :metadata do
	let(:dois) { ['doi:10.what/ever'] }
end

shared_context "indexed with a resolver source uri", shared_context: :metadata do
	let(:resolver_key) { 'rerecord' }
	let(:sources) { ["http://www.columbia.edu/cgi-bin/cul/resolve?#{resolver_key}"] }
end

shared_context "indexed with a url in-context" do
	let(:context_urls) { ['http://www.context.web/item'] }
end

shared_context "indexed with a archive.org id" do
	let(:archive_org_id) { 'internet_archive_id_value' }
end

shared_context "indexed without a display title" do
	let(:title_displays) { nil }
end