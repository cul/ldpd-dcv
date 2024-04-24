class Iiif::BaseResource
  extend Forwardable
  def_delegator 'I18n', :t
  include FieldDisplayHelpers::Repository
  attr_reader :id, :solr_document

  IIIF_CONTEXTS = [
    "https://dlc.library.columbia.edu/schema/iiif/3/context.json",
    "http://iiif.io/api/presentation/3/context.json"
  ].freeze

  def initialize(id:, solr_document:, **args)
    @id = id
    @solr_document = solr_document
  end

  def fedora_pid
    @fedora_pid ||= @solr_document[:fedora_pid_uri_ssi]&.sub('info:fedora/','') || @solr_document[:id]
  end

  def doi
    @doi ||= @solr_document[:ezid_doi_ssim].first&.sub(/^doi:/,'')
  end

  def doi_property
    if self.doi
      { id: "https://doi.org/#{self.doi}" }
    end
  end

  def marcorg
    @marcorg ||= begin
      value_obj = {}
      if @solr_document[:lib_repo_code_ssim].present?
        value_obj[:value] = { none: @solr_document[:lib_repo_code_ssim] }
      else
        value_obj[:value] = { none: ['NNC'] }
      end
      if value_obj.present?
        normal_value = value_obj.dig(:value, :none).first.downcase.gsub('-', '')
        label_value = t("cul.archives.display_value.#{normal_value}", default: false)
        homepage_value = t("cul.archives.url.#{normal_value}", default: false)
        homepage_label = t("cul.archives.physical_location.#{normal_value}", default: false)
        if label_value
          value_obj[:value] = { en: [label_value] }
          value_obj[:label] = { en: ['Location'] }
          see_also = {}
          see_also[:id] = "https://id.loc.gov/vocabulary/organizations/#{normal_value}"
          see_also[:profile] = "https://id.loc.gov/vocabulary/organizations"

          if homepage_value
            see_also[:homepage] = {
              id: homepage_value,
              label: "#{homepage_label} Homepage",
              type: "Text",
              format: "text/html"
            }
          end
          value_obj[:seeAlso] = [see_also]
        else
          value_obj.delete(:value)
        end
      end
      value_obj
    end
  end

  def archival_collection
    @archival_collection ||= begin
      value_obj = {}
      bib_ids = @solr_document[:collection_key_ssim]&.select {|bib_val| bib_val =~ /^\d+$/ }
      if bib_ids.present?
        value_obj[:seeAlso] = bib_ids.map do |bib_id|
          {
            id: generate_finding_aid_url(bib_id, @solr_document),
            profile: 'https://clio.columbia.edu/archives',
          }
        end
      end
      if @solr_document[:lib_collection_ssm]&.first
        value_obj[:value] = { en: @solr_document[:lib_collection_ssm] }
      end
      value_obj[:label] = { en: ['Archival Collection'] } unless value_obj.blank?
      value_obj
    end
  end

  def as_json(opts = {})
    {}
  end

  def to_h(opts = {})
    as_json(opts)
  end

  def to_json(opts = {})
    JSON.pretty_generate(as_json(opts))
  end

end