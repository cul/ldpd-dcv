require 'actionpack/action_caching'
class SquaresController < ActionController::Base

  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::Hydra::Controller
  include ChildrenHelper
  #caches_action :show, :expires_in => 7.days
  
  def show
    obj = ActiveFedora::Base.find(params[:id], cast: true)
    if obj.respond_to? :thumbnail_info
    	url = obj.thumbnail_info
      if (url[:url]  and url[:url] =~ /^https?:/)
        match = /objects\/(.*)\/datastreams/.match(url[:url])
        src_obj = match[1]
        src_obj = ActiveFedora::Base.find(src_obj, cast: true)
        rels = src_obj.rels_int.relationships(:is_part_of)
        streams = []
        p url.inspect
        p "rels: #{rels}"
        rels.each do |rel|
          streams << rel.subject.to_s.split('/')[-1]
        end
        target = params[:scale].to_i
        scale = 0
        candidate = nil
        p streams.inspect
        streams.each do |stream|
          ds = src_obj.datastreams[stream]
          src_obj.rels_int.relationships(ds, :image_width).each do |rel|
            width = rel.object.to_i
            if width <= target and width > scale
              candidate = ds
            end
          end
        end
        p "candidate: #{candidate.inspect}"
        unless candidate.nil?
          t_url =
          "#{ActiveFedora.fedora_config.credentials[:url]}/objects/#{src_obj.pid}/datastreams/#{candidate.dsid}/content"
          cl = http_client
          render :status => 200, :text => cl.get_content(url[:url])
          return
        end
      end
    end
    render :status => 404, :text => "No #{params[:scale]} square found for #{params[:id]}"
  end
end