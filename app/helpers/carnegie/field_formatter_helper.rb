module Carnegie::FieldFormatterHelper
  def append_digital_origin(args={})
    document = args.fetch(:document,{})
    args.fetch(:value,[]).concat document.fetch(:physical_description_digital_origin_ssm,[])
    args.fetch(:value,[])
  end

  def display_origin_info(args={})
    document = args.fetch(:document,{})
    publisher = document.fetch(:lib_publisher_ssm,[]).first
    return [] if publisher
    place = document.fetch('origin_info_place_ssm',[]).first
    date = document.fetch('origin_info_date_created_ssm',[]).first
    date << '.' unless date.nil? || date[-1] == '.'
    [place, date].compact
  end

  def is_dateless_origin_info?(field_config, document)
    date = document.fetch('origin_info_date_created_ssm',[]).first
    publisher = document.fetch(:lib_publisher_ssm,[]).first
    return date.blank? && publisher.blank?
  end

  def is_publication_info?(field_config, document)
    publisher = document.fetch(:lib_publisher_ssm,[]).first
    return publisher.present?
  end

  def display_dateless_origin_info(args={})
    document = args.fetch(:document,{})
    date = document.fetch('origin_info_date_created_ssm',[]).first
    return [] if date
    display_origin_info(args)
  end

  def display_publication_info(args={})
    document = args.fetch(:document,{})
    publisher = document.fetch(:lib_publisher_ssm,[]).first
    return [] unless publisher
    publisher = Array.wrap(publisher)

    place = document.fetch(:origin_info_place_ssm,[]).first
    publisher << place if place
    publisher.each { |part| part.sub!(/[\s\:\.]+$/,'') }
    publisher = publisher.join(': ')
    date = document.fetch(:origin_info_date_created_ssm,[]).first
    date.sub!(/[\s\:\.]+$/,'') unless date.nil?
    [publisher, date].compact.join('. ')
  end

  def display_as_link_to_home(args={})
    args.fetch(:value,[]).map { |e| link_to(e, controller.url_for(action: :index)) }
  end
end
