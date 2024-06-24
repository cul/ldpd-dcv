class Ability
  include CanCan::Ability 
  include Dcv::AccessLevels
  attr_reader :public
  ACCESS_ASSET = :access_asset
  ACCESS_SUBSITE = :access_subsite
  UNSPECIFIED_ACCESS_DECISION = true

  def initialize(user=nil, opts={})
    location_uris = ip_to_location_uris(opts[:remote_ip])
    affils = Array.wrap(opts[:roles]) ||  []
    @public = location_uris.empty? && affils.empty? && user.nil?
    can ACCESS_SUBSITE, SubsitesController do |controller|
      if controller.restricted?
        result = false
        result ||= (controller.subsite_config.fetch(:remote_ids, []).flatten.include?(user.uid)) if user
        result ||= true if (controller.subsite_config.fetch(:remote_roles,[]).flatten & affils).first if user
        result ||= true if (controller.subsite_config.fetch(:locations,[]).flatten & location_uris).first
        result
      else
        true
      end
    end
    can ACCESS_SUBSITE, Site do |site|
      if site.restricted
        result = false
        result ||= (site.to_subsite_config.fetch(:remote_ids, []).flatten.include?(user.uid)) if user
        result ||= true if (site.to_subsite_config.fetch(:remote_roles,[]).flatten & affils).first if user
        result ||= true if (site.to_subsite_config.fetch(:locations,[]).flatten & location_uris).first
        result
      else
        true
      end
    end
    can ACCESS_ASSET, SolrDocument do |doc|
      if doc.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_CLOSED)
        false
      elsif doc.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_PUBLIC)
        true
      elsif doc.fetch('access_control_levels_ssim',[]).blank?
        UNSPECIFIED_ACCESS_DECISION
      else
        result = false
        if doc.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_AFFILIATION)
          result ||= true if (doc.fetch('access_control_affiliations_ssim',[]) & affils).first
        end
        if doc.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_ONSITE)
          result ||= true if (doc.fetch('access_control_locations_ssim',[]) & location_uris).first
          result ||= remote_onsite_access_to_user?(doc, user, affils)
        end
        if doc.fetch('access_control_levels_ssim',[]).include?(ACCESS_LEVEL_EMBARGO)
          result ||= begin
            release_date = doc['access_control_embargo_dtsi']
            DateTime.parse(release_date).httpdate <= Time.now.httpdate  if release_date
          end
        end
        result
      end
    end
    can :update, Site do |site|
      user&.is_admin || site.editor_uids.include?(user&.uid)
    end
    can :admin, Site do |site|
      user&.is_admin
    end
  end

  # was this document published to a site where the current user has remote "onsite" permissions
  def remote_onsite_access_to_user?(doc, user = nil, affils = [])
    return false unless doc['publisher_ssim'].present?
    remote_onsite_access = false
    doc['publisher_ssim'].each do |fedora_uri|
      subsite_config = SubsiteConfig.for_fedora_uri(fedora_uri)
      remote_onsite_access ||= (subsite_config.fetch(:remote_ids, []).flatten.include?(user.uid)) if user
      remote_onsite_access ||= true if (subsite_config.fetch(:remote_roles,[]).flatten & affils).first
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
