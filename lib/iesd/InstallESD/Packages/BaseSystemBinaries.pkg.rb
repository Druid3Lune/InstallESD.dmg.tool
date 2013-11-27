module InstallESD
  class Packages
    class BaseSystemBinaries < PKGUtil::PKG
      def extract_kernel output
        show { |pkg|
          payload = "#{pkg}/Payload"
          cpio = "#{payload}.cpio"
          ohai "Unarchiving #{payload}"
          case `file --brief --mime-type #{payload}`.chomp
          when "application/x-bzip2"
            system("/bin/mv", payload, "#{cpio}.bz2")
            system("/usr/bin/bunzip2", "#{cpio}.bz2")
          when "application/x-gzip"
            system("/bin/mv", payload, "#{cpio}.gz")
            system("/usr/bin/gunzip", "#{cpio}.gz")
          end
          puts "Unarchived: #{cpio}"
          ohai "Extracting /mach_kernel"
          system("/usr/bin/cpio -p -d -I \"#{cpio}\" -- \"#{payload}\" <<</mach_kernel >/dev/null 2>&1")
          system("/bin/mv", "#{payload}/mach_kernel", output)
          puts "Extracted: #{output}"
        }
      end
    end
  end
end
