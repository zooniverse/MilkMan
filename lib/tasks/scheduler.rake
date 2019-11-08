desc "update results collection for completed groups"
task :calculate_results => :environment do
  counter = 0
  
  Group.find_each( :state.in => ['complete', 'active'] ) do |g|
    counter += 1
    puts "#{counter} #{g.zooniverse_id} #{g.name}"
  
    Result.destroy_all( :group_id => g.zooniverse_id )
  
    subject_ids = []
    scan_results = {}
    
    subjects = Subject.fields(:zooniverse_id, :metadata, :classification_count).sort('metadata.page_id').where('group.zooniverse_id' => g.zooniverse_id, 'metadata.has_illustrations_count' => {:$gte => 5})
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
      
      max_size = s['metadata']['original_size'].values.max
      scale = 1400.to_f / max_size
      
      scan_result = scan_results[s.zooniverse_id] || s.cache_scan_result(eps, min)
      result = s.process_labels scan_result
      reduced = {}
      result.each do |type, res|
        reduced[type] = res['reduced'] unless res['reduced'] == []
      end
      # keywords = {}
      keywords = s.keywords()
      
      marks = []
      reduced.each do |type, res|
        res.each do |a|
          mark = {:type => type}
          mark[:coords] = [ a['x'].to_i, a['y'].to_i, a['left'].to_i, a['top'].to_i, a['width'].to_i, a['height'].to_i ]
          value = {}
          a['labels'].each do |label|
            label.each do |k,v|
              value[k] = v.keys
            end
          end
          mark[:value] = value
          marks << mark
        end
      end
      
      result = {
        :subject_id => s.zooniverse_id, 
        :group_id => g.zooniverse_id, 
        :classification_count => s.classification_count, 
        :page_id => s.metadata['page_id'],
        :page => s.metadata['page_no'],
        :volume => s.metadata['volume'],
        :year => s.metadata['year'],
        :reduced => marks, 
        :keywords => keywords.keys,
        :scale => scale
      }
      Result.new( result ).save()
      
    end
  end
end

desc "export results by group to JSON files"
task :export_results => :environment do
  counter = 0

  Group.find_each( :state.in => ['complete', 'active'] ) do |g|
    counter += 1
    puts "#{counter} #{g.zooniverse_id} #{g.name}"

    results = Result.sort(:page_id).all(:group_id => g.zooniverse_id)
    File.open("data/results/#{g.zooniverse_id}.json", 'w') { |file| file.puts results.to_json }
  end
end

desc "export subjects by group to JSON files"
task :export_subjects => :environment do
  counter = 0

  Group.find_each( :state.in => ['complete', 'active'] ) do |g|
    counter += 1
    puts "#{counter} #{g.zooniverse_id} #{g.name}"

    subjects = Subject.sort('metadata.page_id').where('group.zooniverse_id' => g.zooniverse_id, 'metadata.has_illustrations_count' => {:$gte => 5})
    File.open("data/subjects/#{g.zooniverse_id}.json", 'w') { |file| file.puts subjects.to_json }
  end
end

desc "export classifications by subject to JSON files"
task :export_classifications => :environment do
  counter = 0

  Subject.fields(:zooniverse_id).sort(:zooniverse_id).where('metadata.has_illustrations_count' => {:$gte => 5}).find_each do |s|
    counter += 1
    puts "#{counter} #{s.zooniverse_id}"

    classifications = Classification.where(:subject_ids => [s.id])
    File.open("data/classifications/#{s.zooniverse_id}.json", 'w') { |file| file.puts classifications.to_json }
  end
end

desc "export classified groups to JSON files"
task :export_groups => :environment do
  counter = 0

  Group.sort(:zooniverse_id).find_each( :state.in => ['complete', 'active'] ) do |g|
    counter += 1
    puts "#{counter} #{g.zooniverse_id} #{g.name}"

    File.open("data/groups/#{g.zooniverse_id}.json", 'w') { |file| file.puts g.to_json }
  end
end