SUBSITES = YAML.load_file("#{Rails.root.to_s}/config/subsites.yml")[Rails.env]

# Certain sites shouldn't be present on prod
if Rails.env == 'dcv_prod'

  # Disable the following restricted subsites in prod
  SUBSITES['restricted'].delete('ifp')
  SUBSITES['restricted'].delete('universityseminars')

  # Disable the following public subsites in prod
  SUBSITES['public'].delete('ifp')
  #SUBSITES['public'].delete('durst')

end
