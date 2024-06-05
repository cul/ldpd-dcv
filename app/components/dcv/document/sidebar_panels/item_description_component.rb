# frozen_string_literal: true

module Dcv::Document::SidebarPanels
  class ItemDescriptionComponent < ViewComponent::Base
    delegate :site_edit_link, :terms_of_use_url, to: :helpers
    def initialize(document:, citation_presenter: nil, document_presenter: nil, alignment: 'vertical', link_helpers: [])
      @document = document
      @citation_presenter = citation_presenter
      @document_presenter = document_presenter
      @alignment = alignment
      @link_helpers = link_helpers
    end

    def panel_classes
      @panel_classes ||= begin
        _pc = ['inner']
        if @alignment != 'vertical'
          _pc << 'mt-3' << 'border-0' << 'row'
        end
        _pc
      end
    end

    def document_fields
      @document_fields ||= presenter_fields(@document_presenter)
    end

    def citation_fields
      @citation_fields ||= presenter_fields(@citation_presenter)
    end

    def first_chunk
      return field_chunks[0] && to_enum(:first_chunk) unless block_given?
      field_chunks[0]&.each do |data|
        yield *data
      end
    end

    def second_chunk
      return field_chunks[1] && to_enum(:second_chunk) unless block_given?
      field_chunks[1]&.each do |data|
        yield *data
      end
    end

    def field_chunks
      @field_chunks ||= begin
        total_fields = document_fields.length + citation_fields.length
        if total_fields < 5
          return [nil, document_fields + citation_fields]
        end
        chunk_size = (total_fields / 2).ceil
        if chunk_size <= document_fields.length
          first = document_fields[0...chunk_size]
          second = document_fields[chunk_size..-1] + citation_fields
        else
          diff = chunk_size - document_fields.length
          first = document_fields + citation_fields[0...diff]
          second = citation_fields[diff..-1]
        end
        [first, second]
      end
    end

    # returns list of parameterized field name, label value, values array
    def presenter_fields(document_presenter)
      _df = []
      document_presenter.fields_to_render.each do |solr_fname, field, field_presenter|
        _df << [
          solr_fname.parameterize,
          field_presenter.label('show'),
          Array(document_presenter.field_value field)]
      end
      _df
    end

    def before_render
      @citation_presenter ||= helpers.citation_presenter(@document)
      @document_presenter ||= helpers.document_presenter(@document)
    end
  end
end