module ChildrenHelper
  include Cul::Hydra::AccessLevels
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include Dcv::ChildrenHelperBehavior

  def children(id=params[:parent_id], opts={})
    # get the document
    @response, @document = get_solr_response_for_doc_id(id)
    document_children_from_model(@document, opts)
  end

  def child(id=params[:id], opts={})
    # get the document
    @response, @document = get_solr_response_for_doc_id(id, {fl: '*'})
    child_from_solr(@document, document_show_link_field)
  end

  def structured_children
    @structured_children ||= begin
      if @document['structured_bsi'] == true
        children = structured_children_from_solr(@document) || structured_children_from_fedora(@document)
      else
        children = document_children_from_model(@document)[:children]
        # just assign the order they came in, since there's no structure
        children.each_with_index {|child, ix| child[:order] = ix + 1}
      end

      children.map! { |child| child.to_h.with_indifferent_access }
      # the should be hashes from solr documents, with an added keys:
      # - pid
      # - title
      # - order
      # - thumbnail
      # - dc_type
      children
    end
  end

  def has_unviewable_children?
    structured_children.detect { |child| is_unviewable_child?(child) }
  end

  # is this child potentially viewable in a different location, or with a log in?
  def is_unviewable_child?(child)
    !can_access_asset?(child) && child.fetch(:access_control_levels_ssim,[]).detect { |val| !val.eql?(ACCESS_LEVEL_CLOSED) && !val.eql?(ACCESS_LEVEL_EMBARGO) }
  end

  def has_viewable_children?
    structured_children.detect { |child| can_access_asset?(child) }
  end

  def has_closed_children?
    structured_children.detect { |child| !can_access_asset?(child) && child.fetch(:access_control_levels_ssim,[]).include?(ACCESS_LEVEL_CLOSED) }
  end

  def has_embargoed_children?
    structured_children.detect { |child| !can_access_asset?(child) && child.fetch(:access_control_levels_ssim,[]).include?(ACCESS_LEVEL_EMBARGO) }
  end
end
