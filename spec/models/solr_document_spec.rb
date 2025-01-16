require 'rails_helper'
describe SolrDocument do
  include_context "a solr document"
  subject { solr_document }
  context 'is a site result' do
    include_context "indexed from a site object"
    it { is_expected.to be_site_result }
    it { is_expected.not_to have_persistent_url }
    context 'with a source URL' do
      include_context "indexed with a resolver source uri"
      it { is_expected.to have_persistent_url }
      context 'that is an old resolver' do
        let(:resolver_url) { "https://resolver.library.columbia.edu/#{resolver_key}" }
        it { is_expected.to satisfy {|doc| doc.persistent_url == resolver_url} }
      end
    end
    context 'is restricted' do
      include_context "indexed with restrictions"
      it { is_expected.to have_restriction }
      it { is_expected.to satisfy {|doc| doc.slug == "restricted/#{slug}"} }
      it { is_expected.to satisfy {|doc| doc.unqualified_slug == slug} }
    end
    context 'is not restricted' do
      it { is_expected.not_to have_restriction }
      it { is_expected.to satisfy {|doc| doc.slug == slug} }
      it { is_expected.to satisfy {|doc| doc.unqualified_slug == slug} }
    end
  end
  context 'is not a site result' do
    it { is_expected.not_to be_site_result }
    it { is_expected.not_to have_persistent_url }
    context 'with a DOI' do
      include_context "indexed with a doi"
      it { is_expected.to have_persistent_url }
    end
    context 'is restricted' do
      include_context "indexed with restrictions"
      it { is_expected.to have_restriction }
    end
    context 'is not restricted' do
      it { is_expected.not_to have_restriction }
    end
  end
  context 'has no url in-context' do
    let(:context_urls) { nil }
    it { expect(solr_document.item_in_context_url).to be_nil }
  end
  context 'has a url in-context' do
      include_context "indexed with a url in-context"
      it { expect(solr_document.item_in_context_url).not_to be_nil }
      it { expect(solr_document.item_in_context_url).to eql(context_urls.first) }
  end
  context 'has an archive.org id' do
    context 'explicitly defined' do
      include_context "indexed with a archive.org id"
      it { expect(solr_document.archive_org_identifier).not_to be_nil }
    end
    context 'in related URLs' do
      let(:related_urls) { ['https://archive.org/a_value'] }
      it { expect(solr_document.archive_org_identifier).not_to be_nil }
    end
  end
  context 'has no archive.org id' do
    it { expect(solr_document.archive_org_identifier).to be_nil }
  end
  describe '#title' do
    context "when title fields are absent" do
      include_context "indexed without a display title"

      it 'falls back to id if title fields are absent' do
        expect(solr_document.title).to eql solr_document.id
      end
    end
    context "with a title field" do
      let(:title_value) { 'Foo' }
      it 'returns first field value' do
        solr_document.merge_source!(title_ssm: [title_value])
        expect(solr_document.title).to eql title_value
      end
    end
  end
  describe '#clean_resolver' do
    let(:rkey) { 'lweb0138' }
    let(:cgi_http) { "http://www.columbia.edu/cgi-bin/cul/resolve?#{rkey}" }
    let(:cgi_https) { "https://www.columbia.edu/cgi-bin/cul/resolve?#{rkey}" }
    let(:lweb_http) { "https://library.columbia.edu/resolve/#{rkey}" }
    let(:lweb_https) { "https://library.columbia.edu/resolve/#{rkey}" }
    let(:current_https) { "https://resolver.library.columbia.edu/#{rkey}" }
    let(:na_https) { "https://nothing.library.columbia.edu/#{rkey}" }
    it 'cleans cgi style' do
      expect(solr_document.clean_resolver(cgi_http)).to eql(current_https)
      expect(solr_document.clean_resolver(cgi_https)).to eql(current_https)
    end
    it 'cleans lweb style' do
      expect(solr_document.clean_resolver(lweb_http)).to eql(current_https)
      expect(solr_document.clean_resolver(lweb_https)).to eql(current_https)
    end
    it 'passes others through' do
      expect(solr_document.clean_resolver(na_https)).to eql(na_https)
    end
  end
  describe '#has_structure?' do
    it 'is true if structMetadata stream is listed' do
      expect(SolrDocument.new(datastreams_ssim: ['structMetadata']).has_structure?).to be true
    end
    it 'is true if structure boolean is set' do
      expect(SolrDocument.new(structured_bsi: true).has_structure?).to be true
    end
    it 'is otherwise false' do
      expect(solr_document.has_structure?).to be false
    end
  end
end