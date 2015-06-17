# Copyright (c) 2015, Peter Roe
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Astronomical Catalogue Parsers nor the
#       names of their contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PETER ROE BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'yaml'

catalogue_fn = ARGV[0]
yml_fn = ARGV[1]

dsos = []

dso_type_map = {1 => :open_cluster, 2 => :globular_cluster, 3 => :diffuse_nebula,
                4 => :planetary_nebula, 5 => :galaxy, 6 => :cluster_with_nebulosity,
                7 => :nonexistent, 8 => :large_magellanic_object, 9 => :small_magellanic_object,
                0 => :unverified_southern_object}

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

    ngc_number_str = ngc_str[/[0-9]+/]
    ngc_subscript = ngc_str.gsub(ngc_number_str, '')

    # Type (bytes 7-8).
    type_str = ""
    bytes[7..8].each {|b| type_str << b}
    type_str.gsub!(' ', '')
    dso_type = dso_type_map[type_str[0].to_i]

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

    dso = {ngc_number: ngc_number_str.to_i, ngc_subscript: ngc_subscript, dso_type: dso_type,
            right_ascension: ra_num, right_ascension_hours: ra_h_str.to_i,
            right_ascension_minutes: ra_m_str.to_i, declination: dec_num,
            declination_degrees: dec_d_str.to_i, declination_minutes: dec_m_str.to_i,
            magnitude: mag_str.to_f}

    dsos << dso
  end
end

File.open(yml_fn, 'w').write(dsos.to_yaml)
