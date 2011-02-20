class HelloWorldController < SinatraServiceController
  def list
    "Hello #{params[:name]}"
  end
end
