module Dcv::Sites::ReadingRooms
  def reading_room_client?
    (repository_ids_for_client & [params[:repository_id]]).present?
  end

  def location_uris_for_client(remote_ip = request.remote_ip)
    Rails.application.config_for(:reading_rooms).map do |reading_room_id, location|
      if location.fetch(:remote_ip, []).include?(remote_ip.to_s)
        location.fetch(:location_uri, nil)
      end
    end.compact
  end

  def repository_ids_for_client(remote_ip = request.remote_ip)
    Rails.application.config_for(:reading_rooms).map do |reading_room_id, location|
      if location.fetch(:remote_ip, []).include?(remote_ip.to_s)
        location.fetch(:repository_id, nil)
      end
    end.compact
  end
end