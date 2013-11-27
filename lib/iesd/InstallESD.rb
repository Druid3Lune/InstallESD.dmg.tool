Dir[File.join(File.dirname(__FILE__), "InstallESD", "*.rb")].each { |rb| require rb }

module IESD
  def self.new url
    if File.extname(url).downcase == ".app"
      IESD::APP.new url
    else
      IESD::DMG.new url
    end
  end

  module APP
    def self.new url
      if IESD::APP::InstallOSX.validate url
        IESD::APP::InstallOSX.new url
      else
        nil
      end
    end
  end

  module DMG
    def self.new url
      i = nil
      if HDIUtil::validate url
        HDIUtil::DMG.new(url).show { |mountpoint|
          if File.exist? File.join(mountpoint, *%w{.IABootFiles kernelcache})
            i = IESD::DMG::InstallOSX.new url
          elsif File.exist? File.join(mountpoint, *%w{BaseSystem.dmg})
            i = IESD::DMG::InstallESD.new url
          elsif File.exist? File.join(mountpoint, *%w{System Library Caches com.apple.kext.caches Startup kernelcache})
            i = IESD::DMG::BaseSystem.new url
          end
        }
      end
      i
    end
  end
end

