class Ability
  include CanCan::Ability 
  ACCESS_ASSET = :access_asset
  ACCESS_SUBSITE = :access_subsite
  UNSPECIFIED_ACCESS_DECISION = true

  def initialize(user=nil, opts={})
    location_uris = ip_to_location_uris(opts[:remote_ip])
    affils = Array.wrap(opts[:roles]) ||  []
    can ACCESS_SUBSITE, SubsitesController do |controller|
      if controller.restricted?
        result = false
        result ||= (controller.subsite_config.fetch(:remote_ids, []).include?(user.uid)) if user
        result ||= true if (controller.subsite_config.fetch(:remote_roles,[]) & affils).first if user
        result ||= true if (controller.subsite_config.fetch(:locations,[]) & location_uris).first
        result
      else
        true
      end
    end
    can ACCESS_ASSET, SolrDocument do |doc|
      if doc.fetch('access_control_levels_ssim',[]).include?('Closed')
        false
      elsif doc.fetch('access_control_levels_ssim',[]).include?('Public Access')
        true
      elsif doc.fetch('access_control_levels_ssim',[]).blank?
        UNSPECIFIED_ACCESS_DECISION
      else
        result = false
        if doc.fetch('access_control_levels_ssim',[]).include?('On-site Access')
          result ||= true if (doc.fetch('access_control_affiliations_ssim',[]) & affils).first
          result ||= true if (doc.fetch('access_control_locations_ssim',[]) & location_uris).first
        end
        if doc.fetch('access_control_levels_ssim',[]).include?('Embargoed')
          result ||= begin
            release_date = doc['access_control_embargo_dtsi']
            DateTime.parse(release_date).httpdate <= Time.now.httpdate  if release_date
          end
        end
        # if it is published to a site where the current user has explicit remote permissions
        if !result && doc['publisher_ssim'].present?
          doc['publisher_ssim'].each do |fedora_uri|
            subsite_config = SubsiteConfig.for_fedora_uri(fedora_uri)
            result ||= (subsite_config.fetch(:remote_ids, []).include?(user.uid)) if user
            result ||= true if (subsite_config.fetch(:remote_roles,[]) & affils).first
            result
            break if result
          end
        end
        result
      end
    end
  end

  def ip_to_location_uris(remote_ip)
    Rails.application.config_for(:location_uris).map do |location_uri, location|
      if location.fetch('remote_ip', []).include?(remote_ip.to_s)
        location_uri
      end
    end.compact
  end
end
