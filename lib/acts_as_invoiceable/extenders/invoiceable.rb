module ActsAsInvoiceable
  module Extenders
    module Invoiceable 
      def acts_as_invoiceable(options={})
	class_attribute :invoiceable_configuration

	defaults = {
	  number_field: :number,
	  scope: nil
	}
	
	self.invoiceable_configuration = defaults.merge(options)

	require "invoice_numbers"
	require "acts_as_invoiceable/invoiceable"
	include ActsAsInvoiceable::Invoiceable
      end
    end
  end
end
