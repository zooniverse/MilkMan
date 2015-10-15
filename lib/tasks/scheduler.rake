desc "update results collection for export"
task :export_results => :environment do
  counter = 0
  
  Group.find_each() do |g|
    counter += 1
    puts "#{counter} #{g.zooniverse_id} #{g.name}"
  
    Result.destroy_all( :group_id => g.zooniverse_id )
  
    subject_ids = []
    scan_results = {}
    
    subjects = Subject.fields(:zooniverse_id, :metadata, :classification_count).sort('metadata.occurrence_id').where('group.zooniverse_id' => g.zooniverse_id, :classification_count => {:$gte => 5})
    subjects.each do |s|
      subject_ids << s.zooniverse_id
    end
    
    eps = Milkman::Application.config.project["dbscan"]["eps"]
    min = Milkman::Application.config.project["dbscan"]["min"]
    ScanResult.find_each(:zooniverse_id => {:$in => subject_ids}, :eps => eps.to_i, :min => min.to_i) do |s|
      scan_results[s.zooniverse_id] = s.annotations
    end
    
    sub_counter = 0
    subjects.each do |s|
      sub_counter += 1
      puts "processing #{sub_counter} #{s.zooniverse_id}"
      
      scan_result = scan_results[s.zooniverse_id] || s.cache_scan_result(eps, min)
      result = s.process_labels scan_result
      reduced = {}
      result.each do |type, res|
        reduced[type] = res['reduced'] unless res['reduced'] == []
      end
      # keywords = {}
      keywords = s.keywords()
      
      filtered = {}
      keywords.each do |type, votes|
        max_vote = votes.values.max
        votes = votes.select { |k, vote| vote == max_vote }
        votes.each do |choice, vote|
          filtered[type] ||= []
          filtered[type] << {:choice => choice, :vote => vote}
        end
      end
      
      result = {
        :subject_id => s.zooniverse_id, 
        :group_id => g.zooniverse_id, 
        :classification_count => s.classification_count, 
        :metadata => s.metadata,
        :reduced => reduced, 
        :keywords => filtered
      }
      Result.new( result ).save()
      
    end
  end
end