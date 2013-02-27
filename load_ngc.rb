require 'yaml'

class Dso
  attr_accessor :ngc, :alt, :objType, :raStr, :ra, :declStr, :decl, :mag, :desc, :notes
  
  def initialize(ngc, alt, type, ra_str, ra, decl_str, decl, mag, desc, notes)
    @ngc = ngc
    @alt = alt
    @objType = type
    @raStr = ra_str
    @ra = ra
    @declStr = decl_str
    @decl = decl
    @mag = mag
    @desc = desc
    @notes = notes
  end
end

dsos = []

# Open the catalog file.
File.open('rngc_catalog.dat', 'r') do |f|
  id = 0
  
  # Add the DSO from each line to the database.
  f.each_line do |line|
    bytes = []
    
    line.each_byte {|b| bytes << b}
    
    # Build the DSO's properties.
    
    # NGC number (bytes 1-4).
    ngc_str = ""
    bytes[1..4].each {|b| ngc_str << b}
    
    ngc_str << bytes[5] unless bytes[5].nil?
    
    ngc_str.gsub!(' ', '')
    
    # Type (bytes 7-8).
    type_str = ""
    bytes[7..8].each {|b| type_str << b}
    type_str.gsub!(' ', '')

    type = ""

    if type_str == "5"
      type = "GX"
    elsif type_str == "3" or type_str == "4"
      type = "NB"
    elsif type_str == "1" or type_str == "6"
      type = "OC"
    elsif type_str == "2"
      type = "GC"
    else
      type = "other"
    end
    
    # Right ascension hours (bytes 10-11).
    ra_h_str = ""
    bytes[10..11].each {|b| ra_h_str << b}
    ra_h_str.gsub!(' ', '')
    
    # Right ascension minutes (bytes 13-16).
    ra_m_str = ""
    bytes[13..16].each {|b| ra_m_str << b}
    ra_m_str.gsub!(' ', '')
    
    # Combined right ascension string.
    ra_str = "#{ra_h_str} #{ra_m_str}"
    
    # Right ascension numerical value. (Converted from hours to degrees.)
    ra_num = (ra_h_str.to_f + (ra_m_str.to_f / 60.0)) * 15.0
    
    # Declination sign (byte 18).
    dec_s_str = ""
    dec_s_str << bytes[18]
    dec_s_str.gsub!(' ', '')  
    
    # Declination degrees (bytes 19-20).
    dec_d_str = ""
    bytes[19..20].each {|b| dec_d_str << b}
    dec_d_str.gsub!(' ', '')  
    
    # Declination minutes (bytes 22-23).
    dec_m_str = ""
    bytes[22..23].each {|b| dec_m_str << b}
    dec_m_str.gsub!(' ', '')
    
    # Combined declination string.
    dec_str = "#{dec_s_str}#{dec_d_str} #{dec_m_str}"
    
    # Declination numerical value.
    dec_num = dec_d_str.to_f + (dec_m_str.to_f / 60.0)
  
    if dec_s_str == '-'
      dec_num = dec_num * -1.0
    end
    
    # Magnitude (bytes 47-50).
    mag_str = ""
    if bytes[47..50].nil?# or bytes[47..50].empty?
      mag_str = "999999.0"
    else
      bytes[47..50].each {|b| mag_str << b}
    end

    if mag_str.strip.empty?
      mag_str = "999999.0"
    end
    
    mag_str.gsub!(' ', '')  
    
    # Description (bytes 95-150).
    desc_str = ""
    bytes[95..150].each {|b| desc_str << b} unless bytes[95..150].nil?
    desc_str.gsub!(',', ';')
    desc_str.strip!
    
    # Notes (bytes 152-191).
    notes_str = ""
    bytes[152..191].each {|b| notes_str << b} unless bytes[152..191].nil?
    notes_str.gsub!(',', ';')
    notes_str.strip!
    
    dsos << Dso.new(ngc_str, "", type, ra_str, ra_num, dec_str, dec_num, mag_str.to_f, desc_str, notes_str)

    id += 1
  end
end

File.open("dsos_temp.yml", 'w') do |file|
  file.puts dsos.to_yaml
end

File.open("dsos_temp.yml", 'r') do |in_file|
  File.open("dsos.yml", 'w') do |out_file|
    in_file.readlines.each do |line|
      out_file.puts line.gsub("!ruby/object:Dso", "!astrolabe.dso.Dso").gsub("ra:", "ra: !java.lang.Double").gsub("decl:", "decl: !java.lang.Double").gsub("mag:", "mag: !java.lang.Double")
    end
  end
end
