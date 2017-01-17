FactoryGirl.define do
  factory :invoice do

    trait :with_line_items do
      after(:create) { |invoice| create(:invoice_line_item,rate: 100,quantity: 1,invoice: invoice, invoice_item: create(:invoice_item))}
    end

    trait :with_billing_details do
      billing_name {FFaker::Company.name}

      billing_address_1 { FFaker::AddressUS.street_address }
      billing_address_2 "Suite B"
      billing_city{ FFaker::AddressUS.city }
      billing_state{ FFaker::AddressUS.state }
      billing_zip{ FFaker::AddressUS.zip_code }
    end

  end


end
