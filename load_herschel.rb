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

# Parse the Herschel 400 data files from messier.seds.org into YAML.
# Data files are located at:
#     - http://messier.seds.org/xtra/similar/her400l1a.txt
#     - http://messier.seds.org/xtra/similar/her400l2a.txt

require 'yaml'

catalogue_fn = ARGV[0]
yml_fn = ARGV[1]

dsos = []

dso_type_map = {'OCl' => :open_cluster, 'GCl' => :globular_cluster, 'DfN' => :diffuse_nebula,
                'PlN' => :planetary_nebula, 'Gal' => :galaxy, 'C/N' => :cluster_with_nebulosity}

# Open the catalogue file.
File.open(catalogue_fn, 'r') do |f|
  id = 0

  # Add the DSO from each line to the database.
  f.each_line do |line|
    tokens = line.split(' ')

    # Build the DSO's properties.

    # NGC number.
    ngc_str = tokens[0]

    ngc_number_str = ngc_str[/[0-9]+/]
    ngc_subscript = ngc_str.gsub(ngc_number_str, '')

    # Right ascension hours.
    ra_h_str = tokens[1]

    # Right ascension minutes.
    ra_m_str = tokens[2]

    # Right ascension numerical value (in hours).
    ra_num = (ra_h_str.to_f + (ra_m_str.to_f / 60.0))

    # Declination degrees.
    dec_d_str = tokens[3]

    # Declination minutes.
    dec_m_str = tokens[4]

    # Declination numerical value.
    dec_num = dec_d_str.to_f + (dec_m_str.to_f / 60.0)

    # Magnitude.
    mag_str = tokens[5]

    mag_str.gsub!(' ', '')

    # Type.
    type_str = tokens[6]
    dso_type = dso_type_map[type_str]

    dso = {ngc_number: ngc_number_str.to_i, ngc_subscript: ngc_subscript, dso_type: dso_type,
            right_ascension: ra_num, right_ascension_hours: ra_h_str.to_i,
            right_ascension_minutes: ra_m_str.to_i, declination: dec_num,
            declination_degrees: dec_d_str.to_i, declination_minutes: dec_m_str.to_i,
            magnitude: mag_str.to_f}

    dsos << dso
  end
end

File.open(yml_fn, 'w').write(dsos.to_yaml)
