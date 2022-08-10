(define-module (guiska tport)
    #:use-module (ice-9 match)
    #:use-module (guix packages)
    #:use-module (guix download)
    #:use-module (guix gexp)
    #:use-module (guix git-download)
    #:use-module (guix build-system cmake)
    #:use-module ((guix licenses) #:prefix license:)
    #:use-module (gnu packages compression)
    #:use-module (gnu packages pkg-config)
    #:use-module (gnu packages)
    ;#:use-module (gnu packages assembly)
    #:use-module (gnu packages mp3)
    #:use-module (gnu packages audio)
    #:use-module (gnu packages pulseaudio)
    )

(define-public zmusic
  (package
    (name "zmusic")
    (version "1.1.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/ZDoom/ZMusic")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0vpr79gpdbhslg5qxyd1qxlv5akgli26skm1vb94yd8v69ymdcy2"))
       ;(patches (search-patches "zmusic-search-in-installed-share.patch"
                                ;"zmusic-find-system-libgme.patch"))
       (modules '((guix build utils)))
       (snippet
        ;; Remove some bundled libraries.  XXX There are more, but removing
        ;; them would require, at least, patching the build system.
        #~(delete-file-recursively "thirdparty/zlib"))))
    (build-system cmake-build-system)
    (arguments
     (list #:tests? #f
           #:configure-flags
           #~(list (string-append
                    "-DCMAKE_CXX_FLAGS:="
                    "-DSHARE_DIR=\\\"" #$output "/share/\\\" "
                    "-DGUIX_OUT_PK3=\\\"" #$output "/share/games/doom\\\"")

                   ;; The build requires some extra convincing not to use the bundled
                   ;; libgme previously deleted in the soure snippet.
                   "-DFORCE_INTERNAL_GME=OFF"

                   ;; Link libraries at build time instead of loading them at run time.
                   "-DDYN_OPENAL=OFF"
                   "-DDYN_FLUIDSYNTH=OFF"
                   "-DDYN_MPG123=OFF"
                   "-DDYN_SNDFILE=OFF")
           #:phases
           #~(modify-phases %standard-phases
               (add-before 'configure 'fix-referenced-paths
                 (lambda* (#:key inputs #:allow-other-keys)
                   (substitute* "CMakeLists.txt"
                     (("/bin/sh")
                      (search-input-file inputs "bin/sh")))

                   (substitute* (string-append "source/mididevices/"
                                               "music_fluidsynth_mididevice.cpp")
                     (("/usr/share/sounds/sf2/FluidR3_GM.sf2")
                      (search-input-file
                       inputs "share/soundfonts/FluidR3Mono_GM.sf3"))))))))
    ;;TODO ADL and OPl are not present
    ;;I think it'll use the ones in thirdparty/ idk
    (inputs
     (list fluid-3 fluidsynth libgme libsndfile mpg123
           openal wildmidi timidity++ libtimidity zlib))
    (native-inputs (list pkg-config unzip))
    (synopsis "Modern Doom 2 source port")
    (description "GZdoom is a port of the Doom 2 game engine, with a modern
renderer.  It improves modding support with ZDoom's advanced mapping features
and the new ZScript language.  In addition to Doom, it supports Heretic, Hexen,
Strife, Chex Quest, and fan-created games like Harmony, Hacx and Freedoom.")
    (home-page "https://zdoom.org/index")
    ;; The source uses x86 assembly
    (supported-systems (list "x86_64-linux" "i686-linux"))
    (license (list license:gpl3+         ; gzdoom game
                   license:lgpl3+        ; gzdoom renderer
                   license:expat         ; gdtoa
                   (license:non-copyleft ; modified dumb
                    "file://dumb/licence.txt"
                    "Dumb license, explicitly GPL compatible.")))))
zmusic
