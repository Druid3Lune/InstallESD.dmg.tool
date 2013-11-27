require 'tmpdir'

module HDIUtil
  HDIUTIL_BIN = "/usr/bin/hdiutil"
  DEFAULT_MOUNT_OPTIONS = ["-nobrowse", "-quiet"]
  DEFAULT_MOUNT_OPTIONS.concat(["-owners", "on"]) if Process.uid == 0
  DEFAULT_UNMOUNT_OPTIONS = ["-quiet"]
  DEFAULT_CONVERT_OPTIONS = ["-quiet"]

  def self.read input
    Dir.mktmpdir(nil, "/var/tmp") { |mountpoint|
      attach input, mountpoint, [*DEFAULT_MOUNT_OPTIONS]
      if block_given?
        yield mountpoint
      else
        shell mountpoint
      end
      detach input, mountpoint, [*DEFAULT_UNMOUNT_OPTIONS]
    }
  end

  def self.write input, output = input, grow_sectors = 0
    Dir.mktmpdir(nil, "/var/tmp") { |tmp|
      shadow = File.join(tmp, "#{File.basename input}.shadow")
      shadow_options = ["-shadow", shadow]
      format_options = ["-format", `#{HDIUTIL_BIN} imageinfo -format "#{input}"`.chomp]
      Dir.mktmpdir(nil, tmp) { |mountpoint|
        resize_limits = `#{HDIUTIL_BIN} resize -limits -shadow "#{shadow}" "#{input}"`.chomp.split.map { |s| s.to_i }
        sectors = (resize_limits[1] + grow_sectors).to_s
        system(HDIUTIL_BIN, "resize", "-growonly", "-sectors", sectors, *shadow_options, input)
        attach input, mountpoint, [*DEFAULT_MOUNT_OPTIONS, *shadow_options]
        if block_given?
          yield mountpoint
        else
          shell mountpoint
        end
        detach input, mountpoint, [*DEFAULT_UNMOUNT_OPTIONS]
        system(HDIUTIL_BIN, "resize", "-shrinkonly", "-sectors", "min", *shadow_options, input)
      }
      ohai "Merging #{shadow}"
      system(HDIUTIL_BIN, "convert", *DEFAULT_CONVERT_OPTIONS, *format_options, *shadow_options, "-o", output, input)

      flags = `/bin/ls -lO "#{input}"`.split[4]
      system("/usr/bin/chflags", flags, output) unless flags == "-"
      puts "Merged: #{output}"
    }
  end

  def self.validate input
    Kernel.system("#{HDIUTIL_BIN} imageinfo \"#{input}\" >/dev/null 2>&1")
  end

  private

  def self.attach dmg, mountpoint, options = []
    ohai "Mounting #{dmg}"
    system(HDIUTIL_BIN, "attach", *options, "-mountpoint", mountpoint, dmg)
    puts "Mounted: #{mountpoint}"
  end

  def self.detach dmg, mountpoint, options = []
    ohai "Unmounting #{dmg}"
    system(HDIUTIL_BIN, "detach", *options, mountpoint)
    puts "Unmounted: #{mountpoint}"
  end

  def self.shell dir
    Dir.chdir(dir) {
      ohai ENV['SHELL']
      system(ENV, ENV['SHELL'])
    }
  end
end

module HDIUtil
  class DMG
    def initialize url
      @url = File.absolute_path url
    end

    def show &block
      HDIUtil.read(@url, &block)
    end

    def edit
      HDIUtil.write(@url)
    end

    def update &block
      HDIUtil.write(@url, &block)
    end

    def valid?
      HDIUtil.validate @url
    end
  end
end
