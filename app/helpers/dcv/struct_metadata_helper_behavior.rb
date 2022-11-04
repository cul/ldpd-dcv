module Dcv::StructMetadataHelperBehavior
  METS_NS = {'mets' => 'http://www.loc.gov/METS/'}
  def mime_for_name(filename)
    ext = File.extname(filename).downcase
    mt = MIME::Types.type_for(ext)
    if mt.is_a? Array
      mt = mt.first
    end
    unless mt.nil?
      return mt.content_type
    else
      return nil
    end
  end

  def html_class_for_filename(filename)
    mime = mime_for_name(filename) || 'application/octet-stream'
    mime.sub(/\//,'_')
  end
end