class CreateInvoiceNotesAndPayoutRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_notes do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :note_type, null: false, default: "follow_up"
      t.boolean :action_required, null: false, default: false
      t.datetime :resolved_at
      t.text :body, null: false

      t.timestamps
    end

    create_table :payout_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :billing_number, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :requested_at, null: false
      t.datetime :paid_at
      t.string :bank_account_label
      t.text :note

      t.timestamps
    end

    add_index :invoices, [ :placement_id, :invoice_type ], unique: true
  end
end
