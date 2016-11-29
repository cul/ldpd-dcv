SUBSITES = YAML.load_file("#{Rails.root.to_s}/config/subsites.yml")[Rails.env].with_indifferent_access
begin
  Rails.logger.info("loading sites from Solr")
  Blacklight.solr.tap do |rsolr|
    solr_params = {
    qt: 'search',
    rows: 10000,
    fl: 'id,restriction_ssim,slug_ssim',
    fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
    facet: false
    }
    key = :params
    res = rsolr.send_and_receive('select', {key=>solr_params.to_hash, method: :get})
    
    solr_response = Blacklight::SolrResponse.new(res, solr_params, solr_document_model: SolrDocument)
    docs = solr_response['response']['docs']
    docs.each do |doc|
      restriction = doc['restriction_ssim'].blank? ? 'public' : 'restricted'
      next unless doc['slug_ssim']
      slug = doc['slug_ssim'].first
      uri = "info:fedora/#{doc['id']}"
      if (slug == 'sites')
        SUBSITES[restriction]['uri'] = uri
      else
        SUBSITES[restriction][slug]['uri'] = uri unless SUBSITES[restriction][slug].blank?
      end
    end
  end
  open('tmp/subsites.yml','w') { |f| f.write SUBSITES.to_yaml}
rescue Exception => e
  trace = ([e.message] + e.backtrace).join("\n")
  Rails.logger.error(trace)
end