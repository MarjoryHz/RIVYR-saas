class CreateCommissions < ActiveRecord::Migration[8.1]
  def change
    create_table :commissions do |t|
      t.references :placement, null: false, foreign_key: true
      t.string :commission_rule
      t.string :status
      t.integer :gross_amount_cents
      t.integer :rivyr_share_cents
      t.integer :freelancer_share_cents
      t.boolean :client_payment_required
      t.date :eligible_for_invoicing_at

      t.timestamps
    end
  end
end
