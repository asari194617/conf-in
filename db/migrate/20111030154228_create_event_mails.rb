class CreateEventMails < ActiveRecord::Migration[4.2]
  def change
    create_table :event_mails do |t|
      t.integer :event_id
      t.string :subject
      t.text :text

      t.timestamps null: false
    end
  end
end
