include "premake5-tools.lua"

workspace "deadbeef"
   configurations { "debug", "release", "debug32", "release32" }
   platforms { "Windows" }
   defaultplatform "Windows"
defines {
    "VERSION=\"" .. get_version() .. "\"",
    "_GNU_SOURCE",
    "HAVE_LOG2=1"
}

if nls() then
  defines {"ENABLE_NLS"}
  defines {"PACKAGE=\"deadbeef\""}
end

newoption {
  trigger = "standard",
  description = "compile deadbeef with standard set of plugins for windows",
}

if _OPTIONS["standard"] ~= nil then
  plugins_to_disable = {"plugin-artwork", "plugin-converter", "plugin-converter_gtk2",
                        "plugin-converter_gtk3","plugin-ffmpeg","plugin-waveout",
                        "plugin-wildmidi" }
  for i,v in ipairs(plugins_to_disable) do
    if _OPTIONS[v] == nil then
      _OPTIONS[v] = "disabled"
    end
  end
end

defines {"HAVE_ICONV"}

filter "configurations:debug or debug32"
  defines { "DEBUG" }
  symbols "On"

filter "configurations:debug or release"
  buildoptions { "-fPIC" }
  includedirs { "plugins/libmp4ff", "static-deps/lib-x86-64/include/x86_64-linux-gnu", "static-deps/lib-x86-64/include"  }
  libdirs { "static-deps/lib-x86-64/lib/x86_64-linux-gnu", "static-deps/lib-x86-64/lib" }


filter "configurations:debug32 or release32"
  buildoptions { "-std=c99", "-m32" }
  linkoptions { "-m32" }
  includedirs { "plugins/libmp4ff", "static-deps/lib-x86-32/include/i386-linux-gnu", "static-deps/lib-x86-32/include"  }
  libdirs { "static-deps/lib-x86-32/lib/i386-linux-gnu", "static-deps/lib-x86-32/lib" }

filter "configurations:release32 or release"
  buildoptions { "-O2" }

filter "system:Windows"
  buildoptions { "-include shared/windows/mingw32_layer.h", "-fno-builtin"}
  includedirs { "shared/windows/include", "/mingw64/include/opus" }
  libdirs { "static-deps/lib-x86-64/lib/x86_64-linux-gnu", "static-deps/lib-x86-64/lib" }
  defines { "USE_STDIO", "HAVE_ICONV", "_POSIX_C_SOURCE" }

  if nls() then
    links {"intl"}
  end
  links { "ws2_32", "psapi", "shlwapi", "iconv", "libwin", "dl"}

project "libwin"
   kind "StaticLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/"
   files {
       "shared/windows/fopen.c",
       "shared/windows/mingw32_layer.h",
       "shared/windows/rename.c",
       "shared/windows/scandir.c",
       "shared/windows/stat.c",
       "shared/windows/strcasestr.c",
       "shared/windows/strndup.c",
       "shared/windows/utils.c"
   }
   links {"dl"}
   removelinks {"libwin"}

newoption {
    trigger = "debug-console",
    description = "Run deadbeef in console for debug output",
  }

project "deadbeef"
if (_OPTIONS["debug-console"]) then
   kind "ConsoleApp"
else
   kind "WindowedApp"
end
   language "C"
   targetdir "bin/%{cfg.buildcfg}"

   files {
       "*.h",
       "*.c",
       "md5/*.h",
       "md5/*.c",
       "plugins/libparser/*.h",
       "plugins/libparser/*.c",
       "external/wcwidth/wcwidth.c",
       "external/wcwidth/wcwidth.h",
       "shared/ctmap.c",
       "shared/ctmap.h"
   }
   defines { "PORTABLE=1", "STATICLINK=1", "PREFIX=\"donotuse\"", "LIBDIR=\"donotuse\"", "DOCDIR=\"donotuse\"", "LOCALEDIR=\"donotuse\""}
   links { "m", "pthread", "dl"}
   filter "system:Windows"
      files {
        "icons/deadbeef-icon.rc",
        "shared/windows/Resources.rc"
      }

local mp3_v = option ("plugin-mp3", "libmpg123", "mad")
if mp3_v then
project "mp3"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/mp3/mp3.h",
       "plugins/mp3/mp3.c",
       "plugins/mp3/mp3parser.c"
   }
   if mp3_v["libmpg123"] then
      files {
        "plugins/mp3/mp3_mpg123.c",
        "plugins/mp3/mp3_mpg123.h"
      }
      defines { "USE_LIBMPG123=1" }
      links {"mpg123"}
   end
   if mp3_v["mad"] then
      files {
        "plugins/mp3/mp3_mad.c",
        "plugins/mp3/mp3_mad.h"
      }
      defines { "USE_LIBMAD=1" }
      links { "mad" }
   end
end

-- no pkgconfig for libfaad, do checking manually
if _OPTIONS["plugin-aac"] == "auto" or _OPTIONS["plugin-aac"] == nil then
  -- hard-coded :(
  if os.outputof("ls /mingw64/include/neaacdec.h") == nil  then
    print ("\27[93m" .. "neaacdec.h not found in \"/mingw64/include/\", run premake5 with \"--plugin-aac=enabled\" to force enable aac plugin" ..  "\27[39m")
    _OPTIONS["plugin-aac"] = "disabled"
  else
    _OPTIONS["plugin-aac"] = "enabled"
  end
end

if option ("plugin-aac") then
project "aac_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "aac"

   files {
       "plugins/aac/*.h",
       "plugins/aac/*.c",
       "shared/mp4tagutil.h",
       "shared/mp4tagutil.c",
       "plugins/libmp4ff/*.h",
       "plugins/libmp4ff/*.c"
   }

   defines { "USE_MP4FF=1", "USE_TAGGING=1" }
   links { "faad" }
end

if option ("plugin-alac") then
project "alac_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "alac"

   files {
       "plugins/alac/alac_plugin.c",
       "plugins/alac/alac.c",
       "plugins/alac/decomp.h",
       "plugins/alac/demux.c",
       "plugins/alac/demux.h",
       "plugins/alac/stream.c",
       "plugins/alac/stream.h",
       "shared/mp4tagutil.h",
       "shared/mp4tagutil.c",
       "plugins/libmp4ff/*.h",
       "plugins/libmp4ff/*.c"
   }

   defines { "USE_MP4FF=1", "USE_TAGGING=1" }
   links { "faad" }
end

if option ("plugin-flac", "flac ogg") then
project "flac_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "flac"

   files {
       "plugins/flac/*.h",
       "plugins/flac/*.c",
       "plugins/liboggedit/*.h",
       "plugins/liboggedit/*.c",
   }

   defines { "HAVE_OGG_STREAM_FLUSH_FILL" }
   links { "FLAC", "ogg" }
end

if option ("plugin-wavpack", "wavpack") then
project "wavpack_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "wavpack"

   files {
       "plugins/wavpack/*.h",
       "plugins/wavpack/*.c",
   }

   links { "wavpack" }
end

if option ("plugin-ffmpeg") then
project "ffmpeg"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/ffmpeg/*.h",
       "plugins/ffmpeg/*.c",
   }

   links {"avcodec", "pthread", "avformat", "avcodec", "avutil", "z", "opencore-amrnb", "opencore-amrwb", "opus"}
end

if option ("plugin-vorbis", "vorbisfile vorbis ogg") then
project "vorbis_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "vorbis"

   files {
       "plugins/vorbis/*.h",
       "plugins/vorbis/*.c",
       "plugins/liboggedit/*.h",
       "plugins/liboggedit/*.c",
   }

   defines { "HAVE_OGG_STREAM_FLUSH_FILL" }
   links { "vorbisfile", "vorbis", "m", "ogg" }
end

if option ("plugin-opus", "opusfile opus ogg") then
project "opus_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "opus"

   files {
       "plugins/opus/*.h",
       "plugins/opus/*.c",
       "plugins/liboggedit/*.h",
       "plugins/liboggedit/*.c",
   }

   defines { "HAVE_OGG_STREAM_FLUSH_FILL" }
   links { "opusfile", "opus", "m", "ogg" }
   filter "configurations:debug32 or release32"
   
      includedirs { "static-deps/lib-x86-32/include/opus" }

   filter "configurations:debug or release"
   
      includedirs { "static-deps/lib-x86-64/include/opus" }
end

if option ("plugin-ffap") then
project "ffap"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/ffap/*.h",
       "plugins/ffap/*.c",
       "plugins/ffap/dsputil_yasm.asm",
   }

   filter 'files:**.asm'
       buildmessage 'YASM Assembling : %{file.relpath}'

       filter "configurations:debug32 or release32"
           buildcommands
           {
               'yasm -f elf -D ARCH_X86_32 -m x86 -DPREFIX -o "obj/%{cfg.buildcfg}/ffap/%{file.basename}.o" "%{file.relpath}"'
           }

           buildoutputs
           {
               "obj/%{cfg.buildcfg}/ffap/%{file.basename}.o"
           }

           defines { "APE_USE_ASM=yes", "ARCH_X86_32=1" }

       filter "configurations:debug or release"
           buildcommands
           {
               'yasm -f elf -D ARCH_X86_64 -m amd64 -DPIC -DPREFIX -o "obj/%{cfg.buildcfg}/ffap/%{file.basename}.o" "%{file.relpath}"'
           }

           buildoutputs
           {
               "obj/%{cfg.buildcfg}/ffap/%{file.basename}.o"
           }

           defines { "APE_USE_ASM=yes", "ARCH_X86_64=1" }
end

if option ("plugin-hotkeys") then
project "hotkeys"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/hotkeys/*.h",
       "plugins/hotkeys/*.c",
       "plugins/libparser/*.h",
       "plugins/libparser/*.c",
   }
   filter "system:not windows"
       links { "X11" }
end

if option ("plugin-dsp_libsrc", "samplerate") then
project "dsp_libsrc"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/dsp_libsrc/src.c",
   }

   links { "samplerate" }
end

if option ("plugin-portaudio", "portaudio-2.0") then
project "portaudio"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/portaudio/*.h",
       "plugins/portaudio/*.c",
   }
   pkgconfig ("portaudio-2.0")
end

if option ("plugin-waveout") then
project "waveout"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/waveout/*.h",
       "plugins/waveout/*.c",
   }
   links {"winmm", "ksuser"}
end

if option ("plugin-gtk2", "gtk+-2.0 jansson") then
project "ddb_gui_GTK2"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   files {
       "plugins/gtkui/*.h",
       "plugins/gtkui/*.c",
       "shared/eqpreset.c",
       "shared/eqpreset.h",
       "shared/pluginsettings.h",
       "shared/pluginsettings.c",
       "shared/trkproperties_shared.h",
       "shared/trkproperties_shared.c",
       "plugins/libparser/parser.h",
       "plugins/libparser/parser.c",
       "utf8.c",
   }
   excludes {
        "plugins/gtkui/deadbeefapp.c",
        "plugins/gtkui/gtkui-gresources.c"
   }

    pkgconfig ("gtk+-2.0 jansson")

    filter "configurations:debug32 or release32"
    
       includedirs { "static-deps/lib-x86-32/gtk-2.16.0/include/**", "static-deps/lib-x86-32/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-32/gtk-2.16.0/lib", "static-deps/lib-x86-32/gtk-2.16.0/lib/**" }

    filter "configurations:debug or release"
    
       includedirs { "static-deps/lib-x86-64/gtk-2.16.0/include/**", "static-deps/lib-x86-64/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-64/gtk-2.16.0/lib", "static-deps/lib-x86-64/gtk-2.16.0/lib/**" }
end

if option ("plugin-gtk3", "gtk+-3.0 jansson") then
project "ddb_gui_GTK3"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   files {
       "plugins/gtkui/*.h",
       "plugins/gtkui/*.c",
       "shared/eqpreset.c",
       "shared/eqpreset.h",
       "shared/pluginsettings.h",
       "shared/pluginsettings.c",
       "shared/trkproperties_shared.h",
       "shared/trkproperties_shared.c",
       "plugins/libparser/parser.h",
       "plugins/libparser/parser.c",
       "utf8.c",
   }

   prebuildcommands {
  "glib-compile-resources --sourcedir=plugins/gtkui --target=plugins/gtkui/gtkui-gresources.c --generate-source plugins/gtkui/gtkui.gresources.xml"
   }

   pkgconfig("gtk+-3.0 jansson")
   -- links { "jansson", "gtk-3", "gdk-3", "pangocairo-1.0", "pango-1.0", "atk-1.0", "cairo-gobject", "cairo", "gdk_pixbuf-2.0", "gio-2.0", "gobject-2.0", "gthread-2.0", "glib-2.0" }

    filter "configurations:debug32 or release32"

       includedirs { "static-deps/lib-x86-32/gtk-3.10.8/usr/include/**", "static-deps/lib-x86-32/gtk-3.10.8/usr/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-32/gtk-3.10.8/lib/**", "static-deps/lib-x86-32/gtk-3.10.8/usr/lib/**" }

    filter "configurations:debug or release"

       includedirs { "static-deps/lib-x86-64/gtk-3.10.8/usr/include/**", "static-deps/lib-x86-64/gtk-3.10.8/usr/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-64/gtk-3.10.8/lib/**", "static-deps/lib-x86-64/gtk-3.10.8/usr/lib/**" }
end

if option ("plugin-rg_scanner") then
project "rg_scanner"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/rg_scanner/*.h",
       "plugins/rg_scanner/*.c",
       "plugins/rg_scanner/ebur128/*.h",
       "plugins/rg_scanner/ebur128/*.c",
   }
end

if option ("plugin-converter") then
project "converter"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   defines {
      "USE_TAGGING=1"
   }
   files {
       "plugins/converter/converter.c",
       "plugins/libmp4ff/*.c",
       "shared/mp4tagutil.c",
   }
end

if option ("plugin-sndfile", "sndfile") then
project "sndfile_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/sndfile/*.c",
       "plugins/sndfile/*.h",
   }
   links { "sndfile" }
   targetname "sndfile"
end

if option ("plugin-sid") then
project "sid"
   removeplatforms { "Windows" }
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   includedirs {
        "plugins/sid/sidplay-libs/libsidplay/include",
        "plugins/sid/sidplay-libs/builders/resid-builder/include",
        "plugins/sid/sidplay-libs",
        "plugins/sid/sidplay-libs/unix",
        "plugins/sid/sidplay-libs/libsidplay",
        "plugins/sid/sidplay-libs/libsidplay/include",
        "plugins/sid/sidplay-libs/libsidplay/include/sidplay",
        "plugins/sid/sidplay-libs/libsidutils/include/sidplay/utils",
        "plugins/sid/sidplay-libs/builders/resid-builder/include/sidplay/builders",
        "plugins/sid/sidplay-libs/builders/resid-builder/include"
    }
   defines {
      "HAVE_STRCASECMP=1",
      "HAVE_STRNCASECMP=1",
      "PACKAGE=\"libsidplay2\"",
   }

   files {
       "plugins/sid/*.c",
       "plugins/sid/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/*.c",
       "plugins/sid/sidplay-libs/builders/resid-builder/src/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/c64/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/mos6510/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/mos6526/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/mos656x/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/sid6526/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/sidtune/*.cpp",
       "plugins/sid/sidplay-libs/libsidplay/src/xsid/*.cpp",
       "plugins/sid/sidplay-libs/resid/*.cpp"
   }
   targetname "sid"
   links { "stdc++" }
end

if option ("plugin-psf", "zlib") then
project "psf"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   includedirs {
        "plugins/psf",
        "plugins/psf/eng_ssf",
        "plugins/psf/eng_qsf",
        "plugins/psf/eng_dsf",
    }
   defines {
      "HAS_PSXCPU=1",
   }

   files {
        "plugins/psf/plugin.c",
        "plugins/psf/psfmain.c",
        "plugins/psf/corlett.c",
        "plugins/psf/eng_dsf/eng_dsf.c",
        "plugins/psf/eng_dsf/dc_hw.c",
        "plugins/psf/eng_dsf/aica.c",
        "plugins/psf/eng_dsf/aicadsp.c",
        "plugins/psf/eng_dsf/arm7.c",
        "plugins/psf/eng_dsf/arm7i.c",
        "plugins/psf/eng_ssf/m68kcpu.c",
        "plugins/psf/eng_ssf/m68kopac.c",
        "plugins/psf/eng_ssf/m68kopdm.c",
        "plugins/psf/eng_ssf/m68kopnz.c",
        "plugins/psf/eng_ssf/m68kops.c",
        "plugins/psf/eng_ssf/scsp.c",
        "plugins/psf/eng_ssf/scspdsp.c",
        "plugins/psf/eng_ssf/sat_hw.c",
        "plugins/psf/eng_ssf/eng_ssf.c",
        "plugins/psf/eng_qsf/eng_qsf.c",
        "plugins/psf/eng_qsf/kabuki.c",
        "plugins/psf/eng_qsf/qsound.c",
        "plugins/psf/eng_qsf/z80.c",
        "plugins/psf/eng_qsf/z80dasm.c",
        "plugins/psf/eng_psf/eng_psf.c",
        "plugins/psf/eng_psf/psx.c",
        "plugins/psf/eng_psf/psx_hw.c",
        "plugins/psf/eng_psf/peops/spu.c",
        "plugins/psf/eng_psf/eng_psf2.c",
        "plugins/psf/eng_psf/peops2/spu2.c",
        "plugins/psf/eng_psf/peops2/dma2.c",
        "plugins/psf/eng_psf/peops2/registers2.c",
        "plugins/psf/eng_psf/eng_spu.c",
   }
   targetname "psf"
   links { "z", "m" }
end

if option ("plugin-m3u") then
project "m3u"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/m3u/*.c",
       "plugins/m3u/*.h",
   }
end

if option ("plugin-vfs_curl", "libcurl") then
project "vfs_curl"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/vfs_curl/*.c",
       "plugins/vfs_curl/*.h",
   }

   links { "curl" }
end

if option ("plugin-converter_gtk2", "gtk+-2.0") then
project "converter_gtk2"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/converter/convgui.c",
       "plugins/converter/callbacks.c",
       "plugins/converter/interface.c",
       "plugins/converter/support.c",
   }

   pkgconfig ("gtk+-2.0")
   -- links { "gtk-x11-2.0", "pango-1.0", "cairo", "gdk-x11-2.0", "gdk_pixbuf-2.0", "gobject-2.0", "gthread-2.0", "glib-2.0" }

   filter "configurations:debug32 or release32"
       includedirs { "static-deps/lib-x86-32/gtk-2.16.0/include/**", "static-deps/lib-x86-32/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-32/gtk-2.16.0/lib", "static-deps/lib-x86-32/gtk-2.16.0/lib/**" }

   filter "configurations:release or debug"
       includedirs { "static-deps/lib-x86-64/gtk-2.16.0/include/**", "static-deps/lib-x86-64/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-64/gtk-2.16.0/lib", "static-deps/lib-x86-64/gtk-2.16.0/lib/**" }
end

if option ("plugin-converter_gtk3", "gtk+-3.0") then
project "converter_gtk3"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/converter/convgui.c",
       "plugins/converter/callbacks.c",
       "plugins/converter/interface.c",
       "plugins/converter/support.c",
   }

   pkgconfig ("gtk+-3.0")
   -- links { "gtk-x11-2.0", "pango-1.0", "cairo", "gdk-x11-2.0", "gdk_pixbuf-2.0", "gobject-2.0", "gthread-2.0", "glib-2.0" }

   filter "configurations:debug32 or release32"
       includedirs { "static-deps/lib-x86-32/gtk-2.16.0/include/**", "static-deps/lib-x86-32/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-32/gtk-2.16.0/lib", "static-deps/lib-x86-32/gtk-2.16.0/lib/**" }

   filter "configurations:release or debug"
       includedirs { "static-deps/lib-x86-64/gtk-2.16.0/include/**", "static-deps/lib-x86-64/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-64/gtk-2.16.0/lib", "static-deps/lib-x86-64/gtk-2.16.0/lib/**" }
end

if option ("plugin-pltbrowser_gtk2", "gtk+-2.0") then
project "pltbrowser_gtk2"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/pltbrowser/pltbrowser.c",
       "plugins/pltbrowser/support.c"
   }

   pkgconfig ("gtk+-2.0")
   -- links { "gtk-x11-2.0", "pango-1.0", "cairo", "gdk-x11-2.0", "gdk_pixbuf-2.0", "gobject-2.0", "gthread-2.0", "glib-2.0" }

   filter "configurations:debug32 or release32"
       includedirs { "static-deps/lib-x86-32/gtk-2.16.0/include/**", "static-deps/lib-x86-32/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-32/gtk-2.16.0/lib", "static-deps/lib-x86-32/gtk-2.16.0/lib/**" }

   filter "configurations:release or debug"
       includedirs { "static-deps/lib-x86-64/gtk-2.16.0/include/**", "static-deps/lib-x86-64/gtk-2.16.0/lib/**", "plugins/gtkui", "plugins/libparser" }
       libdirs { "static-deps/lib-x86-64/gtk-2.16.0/lib", "static-deps/lib-x86-64/gtk-2.16.0/lib/**" }
end

if option ("plugin-pltbrowser_gtk3", "gtk+-3.0") then
project "pltbrowser_gtk3"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/pltbrowser/pltbrowser.c",
       "plugins/pltbrowser/support.c"
   }

   pkgconfig ("gtk+-3.0")
end

if option ("plugin-wildmidi") then
project "wildmidi_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "wildmidi"

   files {
       "plugins/wildmidi/*.h",
       "plugins/wildmidi/*.c",
       "plugins/wildmidi/src/*.h",
       "plugins/wildmidi/src/*.c",
   }

   excludes {
       "plugins/wildmidi/src/wildmidi.c"
   }

   includedirs { "plugins/wildmidi/include" }

   defines { "WILDMIDI_VERSION=\"0.2.2\"", "WILDMIDILIB_VERSION=\"0.2.2\"", "TIMIDITY_CFG=\"/etc/timidity.conf\"" }
   links { "m" }
end

if option ("plugin-musepack") then
project "musepack_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "musepack"
   files {
       "plugins/musepack/musepack.c",
       "plugins/musepack/huffman.c",
       "plugins/musepack/mpc_bits_reader.c",
       "plugins/musepack/mpc_decoder.c",
       "plugins/musepack/mpc_demux.c",
       "plugins/musepack/mpc_reader.c",
       "plugins/musepack/requant.c",
       "plugins/musepack/streaminfo.c",
       "plugins/musepack/synth_filter.c",
       "plugins/musepack/crc32.c",
       "plugins/musepack/decoder.h",
       "plugins/musepack/huffman.h",
       "plugins/musepack/internal.h",
       "plugins/musepack/mpc_bits_reader.h",
       "plugins/musepack/mpc/mpcdec.h",
       "plugins/musepack/mpcdec_math.h",
       "plugins/musepack/mpc/reader.h",
       "plugins/musepack/requant.h",
       "plugins/musepack/mpc/streaminfo.h",
       "plugins/musepack/mpc/mpc_types.h",
       "plugins/musepack/mpc/minimax.h"
   }
   includedirs { "plugins/musepack" }
   links { "m" }
end

if option ("plugin-artwork", "libjpeg libpng zlib flac ogg") then
project "artwork_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "artwork"

   files {
       "plugins/artwork-legacy/*.c",
       "plugins/libmp4ff/*.c"
   }

   excludes {
   }

   includedirs { "../libmp4ff" }

   defines { "USE_OGG=1", "USE_VFS_CURL", "USE_METAFLAC", "USE_MP4FF", "USE_TAGGING=1" }
   links { "jpeg", "png", "z", "FLAC", "ogg" }
end

if option ("plugin-supereq") then
project "supereq_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "supereq"

   files {
       "plugins/supereq/*.c",
       "plugins/supereq/*.cpp"
   }

   defines { "USE_OOURA" }
   links { "m", "stdc++" }
end

if option ("plugin-mono2stereo") then
project "mono2stereo_plugin"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""
   targetname "ddb_mono2stereo"

   files {
       "plugins/mono2stereo/*.c",
   }
end

if option ("plugin-nullout") then
project "nullout"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/nullout/*.h",
       "plugins/nullout/*.c",
   }
end

if option ("plugin-lastfm", "libcurl") then
project "lastfm"
   kind "SharedLib"
   language "C"
   targetdir "bin/%{cfg.buildcfg}/plugins"
   targetprefix ""

   files {
       "plugins/lastfm/*.h",
       "plugins/lastfm/*.c"
   }
   pkgconfig ("libcurl")
end


project "translations"
   kind "Utility"
   language "C"
   targetprefix ""

   prebuildcommands {
      "for i in po/*.po ; do (echo $$i ; msgfmt $$i -o po/`basename $$i .po`.gmo ) ; done",
   }


project "resources"
    kind "Utility"
    postbuildcommands {
        "{MKDIR} bin/%{cfg.buildcfg}/pixmaps",
        "{COPY} icons/32x32/deadbeef.png bin/%{cfg.buildcfg}",
        "{COPY} pixmaps/*.png bin/%{cfg.buildcfg}/pixmaps/",
        "{MKDIR} bin/%{cfg.buildcfg}/plugins/convpresets",
        "{COPY} plugins/converter/convpresets bin/%{cfg.buildcfg}/plugins/",
    }

project "resources_windows"
    kind "Utility"
    dependson {"translations", "ddb_gui_GTK3", "ddb_gui_GTK2" }
    postbuildcommands {
        "./scripts/windows_postbuild.sh bin/%{cfg.buildcfg}"
    }

print_options()
