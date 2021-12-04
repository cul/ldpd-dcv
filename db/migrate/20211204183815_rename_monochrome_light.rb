class RenameMonochromeLight < ActiveRecord::Migration[5.2]
  def up
    Site.where(palette: 'monochromeLight').update_all(palette: 'monochrome')
  end
 
  def down
    Site.where(palette: 'monochrome').update_all(palette: 'monochromeLight')
  end
end
