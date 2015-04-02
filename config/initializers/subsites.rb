SUBSITES = YAML.load_file("#{Rails.root.to_s}/config/subsites.yml")[Rails.env]

# Certain sites shouldn't be present on prod
if Rails.env == 'dcv_prod'

  # Don't show IFP in public for now
  SUBSITES['public'].delete('ifp')
  SUBSITES['restricted'].delete('ifp')

  # Don't show Durst in public for now
  SUBSITES['public'].delete('durst')

end
