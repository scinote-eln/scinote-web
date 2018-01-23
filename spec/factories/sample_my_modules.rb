FactoryBot.define do
  factory :sample_my_module do
    sample { Sample.frist || create(:sample) }
    my_module { MyModule.frist || create(:my_module) }
  end
end
