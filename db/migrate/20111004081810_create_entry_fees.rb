class CreateEntryFees < ActiveRecord::Migration[4.2]
  def change
    create_table :entry_fees do |t|
      t.integer :entry_id
      t.integer :entry_fee_id
      t.boolean :paid

      t.timestamps null: false
    end
  end
end
