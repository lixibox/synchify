class CreateSynchifyConnectionRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :synchify_connection_requests do |t|
      t.timestamps
      t.json :requester_info, null: false
      t.string :request_key, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
    end

    add_index :synchify_connection_requests, :request_key, unique: true
    add_index :synchify_connection_requests, :status
  end
end
