# frozen_string_literal: true
module Dcv
  class ShowPresenter < Blacklight::ShowPresenter
    include Dcv::FieldPresenters
    def display_type(base_name = nil, default: nil)
      if ['ContentAggregator', 'Collection', 'GenericResource'].include?(document['active_fedora_model_ssi'])
        return document['active_fedora_model_ssi'].underscore
      end
      'default'
    end

    # @return [Hash<String,Configuration::Field>]  all the fields for this index view that should be rendered
    def fields_to_render
      return to_enum(:fields_to_render) unless block_given?

      fields.each do |name, field_config|
        if field_config.pattern
          document.to_h.select {|k,v| k =~ field_config.pattern }.each do |k,v|
            field_clone = field_config.clone.tap { |c| c.field = k }
            field_presenter = field_presenter(field_clone)
            # check for rendering against the original, pattern config
            next unless view_context.should_render_field?(field_config, document) && field_presenter.any?

            yield k, field_clone, field_presenter
          end
          next
        end
        field_presenter = field_presenter(field_config)
        next unless field_presenter.render_field? && field_presenter.any?
        yield name, field_config, field_presenter
      end
    end

    ##
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @param [Hash] options
    # @option options [Boolean] :unique ensures only one link is output for every
    #     content type, e.g. as required by atom
    # @option options [Array<String>] :exclude array of format shortnames to not include in the output
    # @deprecated moved to ShowPresenter#link_rel_alternates
    def link_rel_alternates(options = {})
      Dcv::LinkAlternatePresenter.new(view_context, document, options).render
    end
  end
end