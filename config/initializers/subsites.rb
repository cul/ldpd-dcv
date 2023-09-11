require 'rsolr'
SUBSITES = Rails.application.config_for(:subsites).with_indifferent_access
begin
  Rails.logger.info("loading sites from Solr")
  Blacklight.default_index.tap do |index|
    rsolr = index.connection
    solr_params = {
    qt: 'search',
    rows: 10000,
    fl: 'id,restriction_ssim,slug_ssim',
    fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
    facet: false
    }
    res = rsolr.send_and_receive('select', params: solr_params.to_hash, method: :get)
    solr_response = Blacklight::Solr::Response.new(res, solr_params, solr_document_model: SolrDocument)
    docs = solr_response['response']['docs']
    docs.each do |doc|
      restriction = doc['restriction_ssim'].blank? ? 'public' : 'restricted'
      next unless doc['slug_ssim']
      slug = doc['slug_ssim'].first
      uri = "info:fedora/#{doc['id']}"
      if (slug == 'sites')
        SUBSITES[restriction]['uri'] = uri
      else
        slug_path = slug.split('/')
        slug_context = {'nested' => SUBSITES[restriction] }
        until slug_path.empty?
          slug_context = slug_context.fetch('nested',{}).fetch(slug_path.shift, {})
        end
        slug_context['uri'] = uri unless slug_context.blank?
      end
    end
  end
  open('tmp/subsites.yml','w') { |f| f.write SUBSITES.to_yaml}
rescue Exception => e
  trace = ([e.message] + e.backtrace).join("\n")
  Rails.logger.error(trace)
end