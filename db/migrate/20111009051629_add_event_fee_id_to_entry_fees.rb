class AddEventFeeIdToEntryFees < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_fees, :event_fee_id, :integer
  end
end
