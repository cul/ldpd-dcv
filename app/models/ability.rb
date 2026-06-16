class Ability
  include CanCan::Ability
  include Dcv::AccessLevels
  attr_reader :public

  ACCESS_ASSET = :access_asset
  ACCESS_SUBSITE = :access_subsite
  IMPORT_SUBSITE = :import_subsite
  EDIT_SUBSITES = :edit
  LIST_SUBSITES = :list_subsites
  MANAGE_SUBSITE = :manage_subsite
  UNSPECIFIED_ACCESS_DECISION = true

  def initialize(user = nil, opts = {})
    location_uris = ip_to_location_uris(opts[:remote_ip])
    affils = Array.wrap(opts[:roles]) || []
    @public = location_uris.empty? && affils.empty? && user.nil?
    can ACCESS_SUBSITE, SubsitesController do |controller|
      if controller.restricted?
        result = false
        result ||= controller.subsite_config.fetch(:remote_ids, []).flatten.include?(user.uid) if user
        result ||= true if user && (controller.subsite_config.fetch(:remote_roles, []).flatten & affils).first
        result ||= true if (controller.subsite_config.fetch(:locations, []).flatten & location_uris).first
        result
      else
        true
      end
    end
    
    # can? current_user, :access_subsite, @subsite
    can ACCESS_SUBSITE, Site do |site|
      if site.restricted
        result = false
        result ||= site.to_subsite_config.fetch(:remote_ids, []).flatten.include?(user.uid) if user
        result ||= true if user && (site.to_subsite_config.fetch(:remote_roles, []).flatten & affils).first
        result ||= true if (site.to_subsite_config.fetch(:locations, []).flatten & location_uris).first
        result
      else
        true 
      end
    end

    can ACCESS_ASSET, SolrDocument do |doc|
      if doc.fetch('access_control_levels_ssim', []).include?(ACCESS_LEVEL_CLOSED)
        false
      elsif doc.fetch('access_control_levels_ssim', []).include?(ACCESS_LEVEL_PUBLIC)
        true
      elsif doc.fetch('access_control_levels_ssim', []).blank?
        UNSPECIFIED_ACCESS_DECISION
      else
        result = false
        if doc.fetch('access_control_levels_ssim',
                     []).include?(ACCESS_LEVEL_AFFILIATION) && (doc.fetch('access_control_affiliations_ssim',
                                                                          []) & affils).first
          result ||= true
        end
        if doc.fetch('access_control_levels_ssim', []).include?(ACCESS_LEVEL_ONSITE)
          result ||= true if (doc.fetch('access_control_locations_ssim', []) & location_uris).first
          result ||= remote_onsite_access_to_user?(doc, user, affils)
        end
        if doc.fetch('access_control_levels_ssim', []).include?(ACCESS_LEVEL_EMBARGO)
          result ||= begin
            release_date = doc['access_control_embargo_dtsi']
            DateTime.parse(release_date).httpdate <= Time.now.httpdate if release_date
          end
        end
        result
      end
    end

    return unless user.present?

    is_editor = Site.any? { |site| site[:editor_uids].include? user&.uid }

    return unless is_editor || user.is_admin
    
    can LIST_SUBSITES, Site

    can MANAGE_SUBSITE, Site do |site|
      user.is_admin || site.editor_uids.include?(user.uid)
    end

    can IMPORT_SUBSITE, Site if user.is_admin || !Rails.env.dlc_prod?

    return unless user.is_admin

    can :admin, Site
  end


  #   # A more robust solution would be to add a 'role' field to the user model, so
  #   # we can do an O(1) operation instead of looking at each site when this method runs.
  #   # The react frontend auth does something like that.
  #   # Because we use sqlite3, we cannot do a query that gets the answer reliably (because
  #   # the lookup for an id in the editor array matches substrings, not exacts)
  #   is_editor_or_owner = Site.any? do |site|
  #     site[:editor_uids].include?(user.uid) || site[:owner_uid] == user.uid
  #   end

  #   return unless is_editor_or_owner || user.is_admin

  #   can LIST_SUBSITES, Site

  #   can MANAGE_SUBSITE, Site do |site|
  #     user.is_admin || user.uid == site.owner_uid || site.editor_uids.include?(user.uid)
  #   end

  #   can IMPORT_SUBSITE, Site do |site|
  #     user.is_admin || user.uid == site.owner_uid || !Rails.env.dlc_prod?
  #   end

  #   return unless user.is_admin

  #   can :admin, Site
  # end

  # was this document published to a site where the current user has remote "onsite" permissions
  def remote_onsite_access_to_user?(doc, user = nil, affils = [])
    return false unless doc['publisher_ssim'].present?

    remote_onsite_access = false
    doc['publisher_ssim'].each do |fedora_uri|
      subsite_config = SubsiteConfig.for_fedora_uri(fedora_uri)
      remote_onsite_access ||= subsite_config.fetch(:remote_ids, []).flatten.include?(user.uid) if user
      remote_onsite_access ||= true if (subsite_config.fetch(:remote_roles, []).flatten & affils).first
      break if remote_onsite_access
    end
    remote_onsite_access
  end

  def ip_to_location_uris(remote_ip)
    Rails.application.config_for(:reading_rooms).map do |location_uri, location|
      if location.fetch(:remote_ip, []).map(&:to_s).include?(remote_ip.to_s)
        # the location_uri will be a symbol (configuration key) but compared to strings
        location.fetch(:location_uri, nil)
      end
    end.compact.map(&:to_s)
  end
end
