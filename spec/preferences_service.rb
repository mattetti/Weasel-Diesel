describe_service "preferences.xml" do |service|
  
  service.params do |p|
    p.namespace :preference do |pr|
      pr.string :language_code, :options => ['en', 'fr']
      pr.string :region_code, :options => ['europe']
    end
  end

end
