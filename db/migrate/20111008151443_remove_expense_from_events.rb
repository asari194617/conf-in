class RemoveExpenseFromEvents < ActiveRecord::Migration[4.2]
  def up
    remove_column :events, :expense
  end

  def down
    add_column :events, :expense, :decimal
  end
end
