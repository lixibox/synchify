class AddHookUrlToSynchifyApps < ActiveRecord::Migration[7.0]
  def change
    add_column :synchify_apps, :hook_url, :string
  end
end
