class Result
  include MongoMapper::Document
  include ApplicationHelper
  
  set_collection_name "#{Milkman::Application.config.project["slug"]}_results"

  key :subject_id, String
  key :group_id, String


  key :classification_count, Integer
  key :scale, Float
  key :reduced, Array
  key :keywords, Array
  
  key :page_id, String
  
  def marks(type = 'drawing')
    self.reduced.select{|mark| mark['type'] == type}
  end
  
end