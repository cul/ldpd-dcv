module Dcv::HighlightedSnippetHelper
  
  SNIPPET_HTML_WRAPPER_PRE = '<span class="highlight">'
  SNIPPET_HTML_WRAPPER_POST = '</span>'
  
  def render_snippet_with_post_processing(snippet)
    #remove leading and trailing whitespace AND &nbsp; characters
    snippet.gsub!(/^(&nbsp;|\s)+/, '')
    snippet.gsub!(/(&nbsp;|\s)+$/, '')
    
    highlight_start_placeholder = '!!!HIGHLIGHT-START!!!'
    highlight_end_placeholder = '!!!HIGHLIGHT-END!!!'
    
    #Temporary replace the snippet highlighting html with something that won't be escaped
    snippet.gsub!(/<span class="highlight">(.+)<\/span>/, highlight_start_placeholder + '\1' + highlight_end_placeholder)
    
    #Remove html tags
    snippet = ActionView::Base.full_sanitizer.sanitize(snippet)
    
    #Re-add highlighting html html tags
    snippet.gsub!(highlight_start_placeholder, '<span class="highlight">')
    snippet.gsub!(highlight_end_placeholder, '</span>')
    
    return snippet
  end

end
