class TempJsonsController < ApplicationController

  def new
    @temp_json=JsonTemp.new
  end
  def create
    @temp_json=JsonTemp.new(temp_params)
    json_file_contents=@temp_json.json_file.read
    json_object=JSON.parse(json_file_contents)

  end

  def temp_params
    params.require(:json_file)
  end
end
