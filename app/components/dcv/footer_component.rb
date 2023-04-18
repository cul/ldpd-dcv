# frozen_string_literal: true

module Dcv
  class FooterComponent < ViewComponent::Base
    DEFAULT_VARIANT = 'nnc'
    SLUG_VARIANTS = ['durst', 'universityseminars']
    def initialize(subsite:, repository_id: nil)
      repository_id = DEFAULT_VARIANT if repository_id.blank?
      @repository_code = FooterComponent.variant_for(subsite, repository_id).to_sym
      @local_variants = @repository_code == :nnc ? [@repository_code] : [@repository_code, :nnc]
    end

    def render(*args)
      request_variants = @lookup_context.variants
      @lookup_context.variants = request_variants + (@local_variants - request_variants)
      super
    ensure
      @lookup_context = request_variants
    end

    def self.variant_for(subsite, repository_id)
      return repository_id.downcase.gsub("-","") unless subsite
      return subsite.slug if SLUG_VARIANTS.include? subsite&.slug
      return subsite.repository_id.downcase.gsub("-","") if subsite.repository_id.present?
      return repository_id.downcase.gsub("-","") unless repository_id.blank?
      DEFAULT_VARIANT
    end
  end
end