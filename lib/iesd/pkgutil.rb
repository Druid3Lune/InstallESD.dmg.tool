require 'tmpdir'

module PKGUtil
  PKGUTIL_BIN = "/usr/sbin/pkgutil"

  def self.read input
    Dir.mktmpdir(nil, "/var/tmp") { |tmp|
      tmp = File.join tmp, File.basename(input)
      expand input, tmp
      if block_given?
        yield tmp
      else
        shell tmp
      end
    }
  end

  def self.write input, output = input
    Dir.mktmpdir(nil, "/var/tmp") { |tmp|
      tmp = File.join tmp, File.basename(input)
      expand input, tmp
      if block_given?
        yield tmp
      else
        shell tmp
      end
      flatten tmp, output
    }
  end

  private

  def self.expand pkg, dir
    ohai "Expanding #{pkg}"
    system(PKGUTIL_BIN, "--expand", pkg, dir)
    puts "Expanded: #{dir}"
  end

  def self.flatten dir, pkg
    ohai "Flattening #{dir}"
    system(HDIUTIL_BIN, "--flatten", dir, pkg)
    puts "Flattened: #{pkg}"
  end

  def self.shell dir
    Dir.chdir(dir) {
      ohai ENV['SHELL']
      system(ENV, ENV['SHELL'])
    }
  end
end

module PKGUtil
  class PKG
    def initialize url
      @url = File.absolute_path url
    end

    def show &block
      PKGUtil.read(@url, &block)
    end

    def edit
      PKGUtil.write(@url)
    end

    def update &block
      PKGUtil.write(@url, &block)
    end
  end
end
