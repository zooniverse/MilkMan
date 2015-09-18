class Result
  include MongoMapper::Document
  include ApplicationHelper
  
  set_collection_name "#{Milkman::Application.config.project["slug"]}_results"

  key :subject_id, String
  key :group_id, String


  key :classification_count, Integer
  key :keywords, Array
  
  key :page_id, String
  
end