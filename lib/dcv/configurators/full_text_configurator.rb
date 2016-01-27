class Dcv::Configurators::FullTextConfigurator
  def self.configure(config, replace=true)
    config.default_solr_params ||= {}
    param = {}
    param[:hl] = true
    param[:'hl.fragsize'] = 300
    param[:'hl.usePhraseHighlighter'] = true
    param[:ps] = 0
    param[:qs] = 0
    param[:'hl.maxAnalyzedChars'] = 1000000
    param[:'hl.simple.pre'] = Dcv::HighlightedSnippetHelper::SNIPPET_HTML_WRAPPER_PRE
    param[:'hl.simple.post'] = Dcv::HighlightedSnippetHelper::SNIPPET_HTML_WRAPPER_POST
    if replace
      config.default_solr_params.merge! param
    else
      config.default_solr_params.reverse_merge! param
    end
  end
end
