class CreateEventFees < ActiveRecord::Migration[4.2]
  def change
    create_table :event_fees do |t|
      t.integer :event_id
      t.string :name
      t.integer :sum
      t.text :summary

      t.timestamps null: false
    end
  end
end
