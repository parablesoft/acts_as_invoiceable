module ActsAsInvoiceable
  module Invoiceable
    def self.included(base)
      base.class_eval do

	field = base.invoiceable_configuration[:number_field]
	scope = base.invoiceable_configuration[:scope]

	has_invoice_number field, {assign_if: ->(invoice) { invoice[field].nil? }, prefix: "#{Date.today.year}-", invoice_number_sequence: :invoice, invoice_number_scope: scope}
      end
    end




  end
end
