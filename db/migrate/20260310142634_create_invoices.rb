class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :placement, null: false, foreign_key: true
      t.string :invoice_type
      t.string :number
      t.string :status
      t.date :issue_date
      t.date :paid_date
      t.integer :amount_cents

      t.timestamps
    end
  end
end
