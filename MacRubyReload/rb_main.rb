#
#  rb_main.rb
#  MacRubyReload
#
#  Created by Jean-Denis Muys on 11/15/11.
#  Copyright (c) 2011 Gleamware. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'

module Kernel
  def suppress_warnings
    orig_verbosity = $VERBOSE
    yield.tap { $VERBOSE = orig_verbosity}
  end
end

class MacrubyDevHud
  class << self
    # this function is defined in the main Ruby file so that it can avoid reloading it.
    # only from here can we unambiguously construct the name of the main ruby file
    def main_file_name
      File.basename(__FILE__)
    end
  
    def reloadMacRubySource(dirs=nil)

        dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
        Dir.glob(File.join(dir_path, '*.loc.txt')).each do |loc|

            #        path = IO.read(loc)
            File.open(loc, "r") do |file|
                # currently, location files contain only one line. We loop through all lines anyway for future expansion.
                file.each_line do |path|
                    path = path.gsub(/\r?\n/, '')

                    pathBase = File.basename(path)
                    if File.basename(path) != self.main_file_name
                        load(path)
                    end
                end
            end
        end    
    end

    def macrubySourceDir
      main = File.basename(__FILE__, File.extname(__FILE__))
      dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
      main_loc_file = File.join(dir_path, "#{main}.loc.txt")
      main_loc = File.read(main_loc_file).chomp
      File.dirname(main_loc)
    end

    def loadMacrubySourceInDirs(dirs)
      dirs.each do |dir|
        Dir.glob(File.join(dir, '*.rb')).each do |rbfile|
          unless File.basename(rbfile) == self.main_file_name
            puts "re-loading #{rbfile}"
            suppress_warnings{ load rbfile }
          end
        end
      end
    end
  
    def watchMacrubySource
      Dispatch::Queue.concurrent.async do
        require 'rubygems'
        require 'mrb-fsevent'  
        notifier = FSEvent::Notifier.new
        notifier.watch self.macrubySourceDir do |event_list|
          dirs = event_list.events.map(&:path)
          self.loadMacrubySourceInDirs(dirs)
        end
        notifier.run
      end
    end
  
  end
end

# $dev_hud = MacrubyDevHud.new

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
