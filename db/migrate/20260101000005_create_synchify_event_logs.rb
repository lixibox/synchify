class CreateSynchifyEventLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :synchify_event_logs do |t|
      t.timestamps
      t.references :app, null: false, foreign_key: { to_table: :synchify_apps }
      t.string :direction, null: false
      t.string :event_name, null: false
      t.string :event_id
      t.json :payload
      t.integer :status_code
      t.json :metadata
      t.string :request_id
    end

    add_index :synchify_event_logs, [ :app_id, :event_id ], unique: true
    add_index :synchify_event_logs, :request_id
    add_index :synchify_event_logs, [ :app_id, :event_name ]
  end
end
