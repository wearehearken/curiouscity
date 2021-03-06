=begin
Copyright 2013 WBEZ
This file is part of Curious City.

Curious City is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Curious City is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Curious City.  If not, see <http://www.gnu.org/licenses/>.
=end
class LicenseAdder
  @@supported_types = [".rb", ".scss", ".erb", ".js"]
  def self.supported_types
    @@supported_types
  end

  def rb_gpl(filename)
    rb_license = "=begin\n"+header_license_text+"\n=end\n"
    prepend(filename, rb_license)
  end

  def scss_gpl(filename)
    scss_license = "/*\n" + header_license_text + "\n*/\n"
    prepend(filename, scss_license)
  end

  def erb_gpl(filename)
    true_type = File.extname( filename.chomp(File.extname(filename)) )
    if (true_type == ".js")
      license = "/*\n" + header_license_text + "\n*/\n"
    elsif (true_type == ".html")
      license = "<!--" + header_license_text + "!-->\n"
    end
    prepend(filename, license)
  end

  def js_gpl(filename)
    js_license = "/*\n" + header_license_text + "\n*/\n"
    prepend(filename, js_license)
  end

  private
    def header_license_text
      return "Copyright 2013 WBEZ\nThis file is part of Curious City.\n\nCurious City is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nCurious City is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with Curious City.  If not, see <http://www.gnu.org/licenses/>."
    end

    def prepend(filename, text)
      tempfile = filename+"tmp"
      File.copy_stream(filename, tempfile)
      f = File.open(filename, 'w')
      f.write(text+"#{File.read(tempfile)}")
      f.close
      File.delete(tempfile)
    end
end

require 'find'

path = '/Users/Thoughtworker/Documents/current_projects/wbez/curiouscity/'
Find.find(path) do |filename|
  la = LicenseAdder.new
  if (LicenseAdder.supported_types.include? File.extname(filename))
    p "adding license to " + filename
    la.send(File.extname(filename)[1..-1] + "_gpl", filename)
  end
end
