require "acts_as_invoiceable/version"
require "active_record"
module ActsAsInvoiceable

  if defined?(ActiveRecord::Base)
    require "acts_as_invoiceable/extenders/invoiceable"
    ActiveRecord::Base.extend ActsAsInvoiceable::Extenders::Invoiceable
  end
end
