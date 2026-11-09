class RemoveEntryFeeIdFromEntryFees < ActiveRecord::Migration[4.2]
  def up
    remove_column :entry_fees, :entry_fee_id
  end

  def down
    add_column :entry_fees, :entry_fee_id, :integer
  end
end
