module InstallESD
  class Packages
    class OSInstall < PKGUtil::PKG
      def kext_tool remove_kexts, install_kexts
        script = "#{pkg}/Scripts/postinstall_actions/kext.tool"
        update { |pkg|
          File.open(script, "w") { |f|
            f.write("#!/bin/sh")
            remove_kexts.each { |kext|
              f.write("logger -p install.info \"Removing #{kext}\"")
              f.write("/bin/rm -rf \"$3/System/Library/Extensions/#{kext}\"")
            }
            install_kexts.each { |kext|
              f.write("logger -p install.info \"Installing #{File.basename kext}\"")
              f.write("/bin/cp -R \"/System/Library/Extensions/#{File.basename kext}\" \"$3/System/Library/Extensions/#{File.basename kext}\"")
            }
          }
          File.chmod(0755, script)
        }
      end
    end
  end
end
