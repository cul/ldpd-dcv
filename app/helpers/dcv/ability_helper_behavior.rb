module Dcv::AbilityHelperBehavior
  def can_download?(document=@document)
    if controller.subsite_config['show_original_file_download']
      proxy = Cul::Omniauth::AbilityProxy.new(document_id: document[:id],remote_ip: request.remote_ip,publisher:document[:publisher_ssim])
      can? :download, proxy
    else
      false
    end
  end
end
