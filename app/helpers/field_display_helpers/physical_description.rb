module FieldDisplayHelpers::PhysicalDescription
  def append_digital_origin(args={})
    document = args.fetch(:document,{})
    args.fetch(:value,[]).concat document.fetch(:physical_description_digital_origin_ssm,[])
    args.fetch(:value,[])
  end
end
