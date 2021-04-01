module Dcv::Catalog::CachedFetchBehavior
  extend ActiveSupport::Concern

  def fetch_from_cache(query_term, query_opts, expiry = 30.seconds)
    cache_key = {term: query_term, opts: query_opts}
    doc_src = Rails.cache.fetch(cache_key, expires_in: expiry) do
      r, doc = fetch query_term, query_opts
      doc.to_h
    end
    SolrDocument.new(doc_src)
  end

  def fetch_and_refresh(query_term, query_opts, expiry = 30.seconds)
    cache_key = {term: query_term, opts: query_opts}
    Rails.cache.delete(cache_key)
    doc_src = Rails.cache.fetch(cache_key, expires_in: expiry) do
      r, doc = fetch query_term, query_opts
      doc.to_h
    end
    SolrDocument.new(doc_src)
  end
end
