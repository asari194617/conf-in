class ChangePaidFromEntryFees < ActiveRecord::Migration[4.2]
  def up
    change_column_default 'entry_fees', 'paid', false
  end

  def down
    change_column_default 'entry_fees', 'paid', nil
  end
end
