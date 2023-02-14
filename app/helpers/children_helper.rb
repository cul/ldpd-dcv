module ChildrenHelper
  include Dcv::AccessLevels
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include Dcv::ChildrenHelperBehavior

  def children(id=params[:parent_id], opts={})
    # get the document
    _response, parent_document = fetch(id)
    document_children_from_model(parent_document, opts)
  end

  def child(id=params[:id], opts={})
    # get the document
    _response, child_document = fetch(id, {fl: '*'})
    child_from_solr(child_document, 'title_ssm')
  end

  def structured_children(document = @document)
    document == @document ? memoized_structured_children(document) : structured_children_for_document(document)
  end

  def memoized_structured_children(document)
    @structured_children ||= structured_children_for_document(document)
  end

  def structured_children_for_document(document)
    children = structured_children_from_solr(document) if document['structured_bsi'] == true
    unless children
      children = document_children_from_model(document)[:children]
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

  def is_publicly_available_asset?(child, ability = Ability.new)
    raise "Checking public access against non-public permission context" unless ability.public
    can_access_asset?(child, ability)
  end

  # are any of the assets being denied potentially viewable (not closed or embargoed)
  def has_unviewable_children?(document: @document, children: nil)
    children ||= structured_children(document)
    children.detect { |child| is_unviewable_child?(child) }.present?
  end

  # is this child potentially viewable in a different location, or with a log in?
  def is_unviewable_child?(child)
    !can_access_asset?(child) && child.fetch(:access_control_levels_ssim,[]).detect { |val| !val.eql?(ACCESS_LEVEL_CLOSED) && !val.eql?(ACCESS_LEVEL_EMBARGO) }
  end

  # are any child assets viewable by current user, location, or general public?
  def has_viewable_children?(document: @document, children: nil)
    children ||= structured_children(document)
    children.detect { |child| can_access_asset?(child) }.present?
  end

  # are any of the child assets closed?
  def has_closed_children?
    structured_children.detect { |child| !can_access_asset?(child) && child.fetch(:access_control_levels_ssim,[]).include?(ACCESS_LEVEL_CLOSED) }.present?
  end

  # are any of the child assets embargoed?
  def has_embargoed_children?(document: @document, children: nil)
    children ||= structured_children(document)
    children.detect { |child| !can_access_asset?(child) && child.fetch(:access_control_levels_ssim,[]).include?(ACCESS_LEVEL_EMBARGO) }.present?
  end

  # are any of the child assets restricted from public access?
  def has_restricted_children?
    structured_children.detect { |child| child.fetch(:access_control_levels_ssim,[]).detect {|val| val.present? && val != ACCESS_LEVEL_PUBLIC } }.present?
  end

  # are any of the child assets non-public?
  def has_non_public_children?(document: @document, children: nil, ability: Ability.new)
    children ||= document ? structured_children(document) : []
    children.detect { |child| !is_publicly_available_asset?(child, ability) }.present?
  end

  # are any of the child assets public?
  def has_public_children?(document: @document, children: nil, ability: Ability.new)
    children ||= document ? structured_children(document) : []
    children.detect { |child| is_publicly_available_asset?(child, ability) }.present?
  end
end
