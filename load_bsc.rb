require 'cobravsmongoose'
require 'rexml/document'

catalogue_fn = ARGV[0]
xml_fn = ARGV[1]

stars = []

# Open the catalog file.
File.open(catalogue_fn, 'r') do |f|
  # Add the DSO from each line to the database.
  f.each_line do |line|
    bytes = []
    
    line.each_byte {|b| bytes << b}
    
    # Build the star's properties.
    
    # Bright star number (bytes 1-4).
    bsn_str = ""
    bytes[1..4].each {|b| bsn_str << b}
    
    bsn_str << bytes[5] unless bytes[5].nil?
    
    bsn_str.gsub!(' ', '')

    # Right ascension hours (bytes 76-77).
    ra_h_str = ""
    bytes[76..77].each {|b| ra_h_str << b}
    ra_h_str.gsub!(' ', '')

    # Right ascension minutes (bytes 78-79).
    ra_m_str = ""
    bytes[78..79].each {|b| ra_m_str << b}
    ra_m_str.gsub!(' ', '')

    # Right ascension seconds (bytes 80-83).
    ra_s_str = ""
    bytes[80..83].each {|b| ra_s_str << b}
    ra_s_str.gsub!(' ', '')

    # Combined right ascension string.
    ra_str = "#{ra_h_str} #{ra_m_str} #{ra_s_str}"

    # Right ascension numerical value. (Converted from hours to degrees.)
    ra_num = (ra_h_str.to_f + (ra_m_str.to_f / 60.0) + (ra_s_str.to_f / (60.0 * 60.0))) * 15.0

    # Declination sign (byte 84).
    dec_s_str = ""
    dec_s_str << bytes[84]
    dec_s_str.gsub!(' ', '')

    # Declination degrees (bytes 85-86).
    dec_d_str = ""
    bytes[85..86].each {|b| dec_d_str << b}
    dec_d_str.gsub!(' ', '')

    # Declination minutes (bytes 87-88).
    dec_m_str = ""
    bytes[87..88].each {|b| dec_m_str << b}
    dec_m_str.gsub!(' ', '')

    # Declination seconds (bytes 89-90).
    dec_s_str = ""
    bytes[89..90].each {|b| dec_s_str << b}
    dec_s_str.gsub!(' ', '')

    # Declination numerical value.
    dec_num = dec_d_str.to_f + (dec_m_str.to_f / 60.0) + (dec_s_str.to_f / (60.0 * 60.0))

    if dec_s_str == '-'
      dec_num = dec_num * -1.0
    end

    # Magnitude (bytes 103-107).
    mag_str = ""
    if bytes[103..107].nil?# or bytes[47..50].empty?
      mag_str = "999999.0"
    else
      bytes[103..107].each {|b| mag_str << b}
    end

    if mag_str.strip.empty?
      mag_str = "999999.0"
    end

    mag_str.gsub!(' ', '')
    
    star = {'bscNumber' => {'$' => bsn_str}, 'rightAscension' => {'$' => ra_num.to_s},
            'rightAscensionHours' => {'$' => ra_h_str}, 'rightAscensionMinutes' => {'$' => ra_m_str},
            'declination' => {'$' => dec_num.to_s}, 'declinationDegrees' => {'$' => dec_d_str},
            'declinationMinutes' => {'$' => dec_m_str}, 'magnitude' => {'$' => mag_str}}

    stars << star
  end
end

bsc = {'BSC' => {'Star' => stars}}

REXML::Document.new(CobraVsMongoose.hash_to_xml(bsc)).write(File.open(xml_fn, 'w'), 2)
