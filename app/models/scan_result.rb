class ScanResult
  include MongoMapper::Document
  set_collection_name "#{Milkman::Application.config.project["slug"]}_scan_results"

  key :zooniverse_id, String
  key :annotations, Hash
  key :type, String
  key :state, String
  key :classification_count, Integer
  timestamps!

  def subject
    Subject.find_by_zooniverse_id(self.zooniverse_id)
  end

end
