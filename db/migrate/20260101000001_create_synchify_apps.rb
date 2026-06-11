class CreateSynchifyApps < ActiveRecord::Migration[6.0]
  def change
    create_table :synchify_apps do |t|
      t.timestamps
      t.string :name, null: false
      t.string :app_code, null: false
      t.text :api_key
      t.text :secret_token
      t.string :app_url
      t.string :hook_url
      t.string :status, null: false, default: "requested"
      t.string :connection_state, null: false, default: "active"
    end

    add_index :synchify_apps, :app_code, unique: true
  end
end
