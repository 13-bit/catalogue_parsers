require 'cobravsmongoose'
require 'rexml/document'

catalogue_fn = ARGV[0]
xml_fn = ARGV[1]

dsos = []

# Open the catalogue file.
File.open(catalogue_fn, 'r') do |f|
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
    
    # Right ascension hours (bytes 10-11).
    ra_h_str = ""
    bytes[10..11].each {|b| ra_h_str << b}
    ra_h_str.gsub!(' ', '')
    
    # Right ascension minutes (bytes 13-16).
    ra_m_str = ""
    bytes[13..16].each {|b| ra_m_str << b}
    ra_m_str.gsub!(' ', '')
    
    # Right ascension numerical value (in hours).
    ra_num = (ra_h_str.to_f + (ra_m_str.to_f / 60.0))
    
    # Declination sign (byte 18).
    dec_s_str = ""
    dec_s_str << bytes[18]
    dec_s_str.gsub!(' ', '')  
    
    # Declination degrees (bytes 19-20).
    dec_d_str = (dec_s_str == '-') ? dec_s_str : ''
    bytes[19..20].each {|b| dec_d_str << b}
    dec_d_str.gsub!(' ', '')  
    
    # Declination minutes (bytes 22-23).
    dec_m_str = ""
    bytes[22..23].each {|b| dec_m_str << b}
    dec_m_str.gsub!(' ', '')
    
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
    
    dso = {'ngcNumber' => {'$' => ngc_str}, 'dsoType' => {'$' => type_str},
            'rightAscension' => {'$' => ra_num.to_s}, 'rightAscensionHours' => {'$' => ra_h_str},
            'rightAscensionMinutes' => {'$' => ra_m_str}, 'declination' => {'$' => dec_num.to_s},
            'declinationDegrees' => {'$' => dec_d_str}, 'declinationMinutes' => {'$' => dec_m_str},
            'magnitude' => {'$' => mag_str}}
    
    dsos << dso
  end
end

rngc = {'RNGC' => {'DSO' => dsos}}

REXML::Document.new(CobraVsMongoose.hash_to_xml(rngc)).write(File.open(xml_fn, 'w'), 2)
