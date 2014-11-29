require 'fileutils'

class PropertiesController < ApplicationController
  before_action :ensure_authorized, :only => [:new, :create]

  def new
    @property = Property.new
    flash[:notice] = "Property successfully added"
  end

  def create
    @property = Property.new property_params
    @property.user = current_user

    if @property.save

      5.times do |i|
        unless params["photos#{i}"] == "" || params["photos#{i}"].nil?
          Photo.new({:file => upload_photo(params["photos#{i}"], i),
                     :property => @property}).save
        end
      end

      redirect_to action: 'index' #TODO do something more logical instead
    else
      puts @property.errors.full_messages
      render 'new'
    end
  end

  #Added destroy action
  def destroy
    Property.find(params[:id]).destroy
    flash[:notice] = "Property successfully destroyed"
    redirect_to properties_path
  end

  def index
    @properties = Property.all
    @properties = Property.paginate(page: params[:page])
    @photos = {}

    @properties.each do |prop|
      property_photo = []
      Photo.where("property_id = ?", prop.id).each do |photo|
        property_photo.push(photo.file)
      end
      @photos[prop.id] = property_photo
    end
  end

  private

  def property_params
    params.require(:property).permit(:prop_type,
                                     :location,
                                     :address,
                                     :number_bathrooms,
                                     :number_bedrooms,
                                     :number_other_rooms,
                                     :rent_price)
  end

  def ensure_authorized
    unless(current_user.is_role_by_name?("admin") ||
           current_user.is_role_by_name?("owner"))
      render 'common/not_authorized'
    end
  end

  def upload_photo file_io, index
    photo_name = "uploads/" + @property.id.to_s 
    file_name = Rails.root.join('app', 'assets', 'images', photo_name)

    FileUtils::mkdir_p file_name

    photo_name = photo_name + "/" +file_io.original_filename
    file_name = file_name.join(file_io.original_filename)

    File.open(file_name, 'wb') do |file|
      file.write(file_io.read)
    end

    return photo_name.to_s
  end
end
