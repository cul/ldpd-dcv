SUBSITES = YAML.load_file("#{Rails.root.to_s}/config/subsites.yml")[Rails.env]

# Certain sites shouldn't be present on prod
if Rails.env == 'dcv_prod'
  SUBSITES['public'].delete('ifp')
  SUBSITES['restricted'].delete('ifp')
end
