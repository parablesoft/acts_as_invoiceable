FactoryGirl.define do
  factory :invoice_item do
    name {FFaker::Name.name}
    qb_id {FFaker::Product.model}
    trait :freight do
      name "Freight"
    end

  end

end
