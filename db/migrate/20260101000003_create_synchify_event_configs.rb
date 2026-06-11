class CreateSynchifyEventConfigs < ActiveRecord::Migration[6.0]
  def change
    create_table :synchify_event_configs do |t|
      t.timestamps
      t.references :app, null: false, foreign_key: { to_table: :synchify_apps }
      t.string :direction,  null: false
      t.string :event_name, null: false
      t.string :state,      null: false, default: "disabled"
    end

    add_index :synchify_event_configs, [ :app_id, :direction, :event_name ], unique: true, name: :synchify_event_configs_unique_keys
  end
end
