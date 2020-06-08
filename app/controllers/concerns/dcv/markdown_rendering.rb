require 'blacklight/catalog'

module Dcv::MarkdownRendering
  extend ActiveSupport::Concern

  def markdown_renderer
    @markdown_renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      autolink: true, tables: true, filter_html: true)
  end

  def render_markdown(markdown)
    markdown_renderer.render(markdown).html_safe
  end
end
