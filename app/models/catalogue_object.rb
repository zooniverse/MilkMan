class CatalogueObject
  include MongoMapper::Document
  set_collection_name "#{Milkman::Application.config.project["slug"]}_catalogue_objects"

  key :type, String
  key :glon, Float
  key :glat, Float
  key :degx, Float
  key :degy, Float
  key :imgx, Float
  key :imgy, Float
  key :rx, Float
  key :ry, Float
  key :angle, Float
  key :qglon, Float
  key :gqlat, Float
  key :qdegx, Float
  key :qdegy, Float
  key :potential_duplicate, Boolean
  key :pixel_scale, Float
  key :zooniverse_id, String
  key :img_url, String

  key :catalogue_name, String
  key :cat_id, String
  timestamps!

  def subject
    Subject.find_by_zooniverse_id(self.zooniverse_id)
  end

end
