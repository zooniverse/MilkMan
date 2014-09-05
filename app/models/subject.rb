require 'open-uri'
require 'json'

class Subject
  include MongoMapper::Document
  include ApplicationHelper
  # many :classifications
  set_collection_name "#{Milkman::Application.config.project_slug}_subjects"

  key :project_id, ObjectId
  key :workflow_ids, Array
  key :zooniverse_id, String
  key :state, String

  key :location, Hash
  key :classification_count, Integer
  key :coords, Array

  key :metadata, Hash
  key :size, String

  key :group_id, ObjectId, :optional
  key :group_type, String, :optional
  # timestamps

  scope :near_to, lambda {|centre| where(:id => {'$in' => Subject.near(centre)}) }

  def is_tutorial?
    return self.respond_to?('tutorial') ? TRUE : FALSE
  end

  def switched?
    unless self.group_id.nil?
      return self.group["zooniverse_id"].in? ["GMW0000003", "GMW0000004", "GMW0000005", "GMW0000006", "GMW0000007"]
    else
      return false
    end
  end

  def real_spread(input)
    adjacent = 100.0
    hypotenuse = adjacent / Math.cos(input.to_f/(180.0/3.14159265359))
    opposite = hypotenuse * Math.sin(input.to_f/(180.0/3.14159265359))
    inradius = (adjacent * opposite) / (adjacent + opposite + hypotenuse)
    renderedOpposite = inradius * 2
    renderedAdjacent = adjacent - renderedOpposite
    renderedAngle = Math.atan(renderedOpposite / renderedAdjacent)
    renderedSpread = renderedAngle * 2
    return renderedSpread*(180.0/3.14159265359)
  end

  def classifications
    Classification.where(:subject_ids => [Subject.find_by_zooniverse_id(self.zooniverse_id).id])
  end

  def user_names
    self.classifications.map{|c|c.user_name}.uniq
  end

  def annotations
    unless self.is_tutorial? #Exclude tutorial
      self.classifications.map{|c|c.annotations}.flatten.select{|i|i["center"]||i["source"]}
    else
      return {}
    end
  end

  def save_scan(data, type="dbscan")
    s = ScanResult.create(
      :zooniverse_id => self.zooniverse_id,
      :subject_id => self.id,
      :type => type,
      :state => self.state,
      :classification_count => self.classification_count,
      :annotations => data
    )
    puts "Created data for #{self.zooniverse_id}"
    return s.annotations
  end

  def self.random
    s = ScanResult.where(:classification_count => {:$gte => 50})
    s.skip(rand(s.size-1)).first
  end

<<<<<<< 802566f9489216e05b3fa5ed7d4645a427bbccf2
  def annotations_by_type(o="ego")
    self.annotations.select{|a| a if a["name"]==o || a["content"]==o}
=======
  def annotations_by_type(o="blotch")
    self.annotations.select{|a| a if a["type"]==o}
>>>>>>> Planet Four Branch
  end

  def dbscan_by_type(o,min_points,epsilon)
    output = { "raw"=>[], "reduced"=>[], "signal"=>{}, "noise"=>[] }
    objects = self.annotations.select{|a| a if a["type"]==o}
    objects.each do |i|
      
      if o=="fan"
        rot = i["angle"].to_f%180
        rx = i["distance"].to_f
        ry = i.has_key?("version") ? i["spread"] : real_spread(i["spread"])
        output["raw"] << [i["source"]["x"].to_f, i["source"]["y"].to_f, rx, ry, (5.0/90.0)*(rot%90.0) ]   
      end

      if o=="blotch"    
        rot = i["angle"].to_f%180
        rx = rot>90 ? i["radius2"].to_f : i["radius1"].to_f
        ry = rot>90 ? i["radius1"].to_f : i["radius2"].to_f
        output["raw"] << [i["center"]["x"].to_f, i["center"]["y"].to_f, rx, ry, (5.0/90.0)*(rot%90.0) ]
      end

    end

    dbscan = Clusterer.new( output["raw"], {:min_points => min_points, :epsilon => epsilon})
    dbscan.results.each do |k, arr|
      unless k==-1
        output["signal"]["#{k}"] = arr.map{|i| { "x" => i[0], "y" => i[1], "rx" => i[2], "ry" => i[3], "angle" => (90.0/5.0)*i[4] } }

        avx   = arr.transpose[0].inject{|sum, el| sum+el }.to_f/arr.size
        avy   = arr.transpose[1].inject{|sum, el| sum+el }.to_f/arr.size
        avrx  = arr.transpose[2].inject{|sum, el| sum+el }.to_f/arr.size
        avry  = arr.transpose[3].inject{|sum, el| sum+el }.to_f/arr.size
        avrot = arr.transpose[4].inject{|sum, el| sum+el }.to_f/arr.size

        qy  = stdev(arr.transpose[0])
        qx  = stdev(arr.transpose[1])
        qry = stdev(arr.transpose[3])
        qrx = stdev(arr.transpose[2])

        qdegy = qry*self.pixel_scale
        qdegx = qrx*self.pixel_scale

        glat  = self.glat-((avy-200)*self.pixel_scale)
        glon  = self.glon-((avx-400)*self.pixel_scale)

        qglat = qy*self.pixel_scale.abs
        qglon = qx*self.pixel_scale.abs

        quality = { "qx"=>qx, "qy"=>qy, "qrx"=>qrx, "qry"=>qry, "qdegx"=>qdegx, "qdegy"=>qdegy, "qglat" => qglat, "qglon" => qglon }

        output["reduced"] << { "glon" => glon, "glat" => glat, "x" => avx, "y" => avy, "rx" => avrx, "degy" => avry*self.pixel_scale, "degx" => avrx*self.pixel_scale, "ry" => avry, "angle" => (90.0/5.0)*avrot, "quality" => quality }
      else
        output["noise"] = arr.map{|i| { "x" => i[0], "y" => i[1], "rx" => i[2], "ry" => i[3], "angle" => i[4] } }
      end
    end
    return output
  end

  def cache_scan_result()
    res = ScanResult.first(:zooniverse_id => self.zooniverse_id)
    if res.nil?
      puts "Caching result for #{self.zooniverse_id}"
      return self.dbscan
    else
      if (res.created_at < 30.days.ago && res.classification_count == self.classification_count)
        ScanResult.find_all_by_zooniverse_id(self.zooniverse_id).each{|r|r.delete}
        return self.dbscan
        puts "New result saved for #{self.zooniverse_id}"
      else
        # puts "Result found for #{self.zooniverse_id}"
        return res.annotations
      end
    end
  end

  def dbscan(min_points=5, epsilon=25)
    # types = ["bubble", "cluster", "ego", "galaxy"]
    types = Milkman::Application.config.object_types
    result = {}
    types.each do |o|
      result[o] = self.dbscan_by_type(o,min_points, epsilon)
    end
    save_scan(result, "dbscan")
    return result
  end

  def self.cache_results(n=10)
    completed_ids = ScanResult.all.map{|s|s.zooniverse_id}
    k=0
    Subject.where(:state => "complete", :zooniverse_id.nin => completed_ids, :tutorial.ne => true).sort(:classification_count.desc).limit(n).each do |i|
      i.cache_scan_result
      k+=1
      puts "#{k}/#{n}"
    end
  end

  def self.find_in_range(l,b)
    r = 0.075
    Subject.where(:$or => [{:state => "complete"}, {:state => "legacy"}], :coords => {:$elemMatch => {:$gt => l-r, :$lt => l+r}}).select{|i| i.glat>b-r && i.glat<b+r }
  end

  def self.near(centre)

    distance = 0.075
    regionals = []
    lows  = Subject.where(:coords => {:$elemMatch => {:$gte => centre[0]-distance, :$gte => centre[1]-distance}}).to_a
    lows.each{|s| regionals<<s if s.coords[0]<=centre[0]+distance && s.coords[1]<=centre[1]+distance } # && s.metadata["size"]=="0.1500x0.0750" }

    subjects = {}
    regionals.each do |s|
      dist = Math.sqrt( ((s.coords[0]-centre[0]) * (s.coords[0]-centre[0])) + ((s.coords[1]-centre[1]) * (s.coords[1]-centre[1])) )
      subjects[s.id] = dist
    end

    subjects.values.sort!
    return subjects.select {|k, v| v < distance}.keys

  end

  def self.cache_near(l,b,r)

    completed_ids = ScanResult.all.map{|s|s.zooniverse_id}
    set = Subject.where(:state => "complete", :zooniverse_id.nin => completed_ids, :tutorial.ne => true, :coords => {:$elemMatch => {:$gt => l-r, :$lt => l+r}}).select{|i| i.glat>b-r && i.glat<b+r }
    puts "Found #{set.size} subjects"
    set.each do |i|
      i.cache_scan_result
    end

  end

  def glat
  	self.switched? ? self.coords[1].to_f : self.coords[0].to_f
  end

  def glon
  	self.switched? ? self.coords[0].to_f : self.coords[1].to_f
  end

  def width
    return 1.2962962963
   # if self.state == "legacy"
   #    s = self.location["standard"]
   #    if s.index('bubble_centred')
   #      s[s.index('mosaic_')+7..s.index('_I24M1.jpg')-1].split('x')[0].to_f
   #    else
   #      s[s.index('h/')+2..s.index('_jpgs')-1].split('x')[0].to_f
   #    end
   #  else
   #    self.metadata["size"].split(/x/)[0].to_f
   #  end
  end

  def height
    return 1
  	# if self.state == "legacy"
   #    s = self.location["standard"]
   #    if s.index('bubble_centred')
   #      s[s.index('mosaic_')+7..s.index('_I24M1.jpg')-1].split('x')[1].to_f
   #    else
   #      s[s.index('h/')+2..s.index('_jpgs')-1].split('x')[1].to_f
   #    end
   #  else
   #    self.metadata["size"].split(/x/)[1].to_f
   #  end
  end

  def pixel_scale
  	xs = self.width.to_f/Milkman::Application.config.image["width"]
  	ys = self.height.to_f/Milkman::Application.config.image["height"]

  	return xs.round(5)==ys.round(5) ? xs : "scale conflict"
  end

  def image
    self.location["standard"]
  end

  def dr1
    if (self.state=="legacy" && ( self.location["standard"].index("th/") || self.location["standard"].index("bubble_centred") ))
      return true
    else
      return false
    end
  end

  def object_count(o)
  	self.metadata["markings"] ? self.metadata["markings"][o+"_count"].to_i : 0
  end

  def empty_image?
  	if self.metadata["markings"]
  		if self.object_count("blank")>=5 && self.state=="complete" && self.classification_count<=10
  		  return true
	  	else
	  	  return false
	    end
    else
	    return false
  	end
  end

  def simbad_url(radius=self.width*10, top=5000)
    #Define corners of search box
    centre = gal2equ(self.glon, self.glat)
    eqlow  = [centre[0]-self.width*2, centre[1]-self.width]
    eqhigh = [centre[0]+self.width*2, centre[1]+self.width]

    #Build URL
    url_start = "http://simbad.u-strasbg.fr/simbad/sim-tap/sync?request=doQuery&lang=ADQL&format=JSON&query="
    get_url = url_start+URI::encode("SELECT TOP #{top} basic.OID, RA, DEC, main_id, coo_bibcode, filter, flux, ident.id, otype, flux.bibcode FROM basic, flux JOIN ident USING(oidref) WHERE flux.oidref = basic.oid AND ra < #{eqhigh[0]} AND ra > #{eqlow[0]} AND dec < #{eqhigh[1]} AND dec > #{eqlow[1]}")

  end

  def simbad_gal_list(radius=self.width*10, top=5000)
    data = self.search_simbad(radius, top)
    new_data = []
    data.each do |o|
      gco = equ2gal(o["ra"], o["dec"])
      o["glat"] = gco[0]
      o["glon"] = gco[1]
      new_data << o
    end
    return new_data
  end

  def simbad_for_svg(radius=self.width*10, top=5000)
    data = self.search_simbad(radius, top)
    new_data = []
    data.each do |o|
      gco = equ2gal(o["ra"], o["dec"])
      xoff = ( gco[0] - self.glon ) / self.pixel_scale
      yoff = ( gco[1] - self.glat ) / self.pixel_scale
      o["x"] = 400 - xoff
      o["y"] = -(200 + yoff)
      new_data << o
    end
    return new_data
  end

  def search_simbad(radius=self.width*10, top=5000)

    get_url=self.simbad_url(radius, top)
    # the_data = Rails.cache.fetch("simbad-#{radius}-#{top}", :expires_in => 6.hours) {
      json = open("#{get_url}").read
      the_data =  JSON.parse(json)
      puts "No data returned" if json.empty?
    # }

    output = Array.new
    if the_data["data"].size > 0
      map = the_data["data"].map {|item| {item[3] => {"object_name" => item[3], "type" => item[8], "bibcode" => item[4], "ra" => item[1], "dec" => item[2], item[5] => mag2flux(item[6],item[5]), "other_name" => item[7], "other_bib" => item[9] } } }
      red = map.reduce({}) {|h,pairs| pairs.each {|k,v| (h[k] ||= []) << v}; h}
      red.each do |r|
        #Collect up names and bibcodes and merge objects into single entries
        names = r[1].collect {|i| i["other_name"] }
        bibs = r[1].collect {|i| i["other_bib"] }
        obj = r[1].inject { |all, h| all.merge!(h) }

        #Clean up and format object names
        obj.delete("other_name")
        obj["all_names"] = (names).uniq!

        #Clean up and format bibcodes
        obj.delete("other_bib")
        bibs << obj["bibcode"]
        obj.delete("bibcode")
        obj["bibcodes"] = (bibs).uniq!

        #output object
        output << obj
      end
    end

    return output

  end

end
