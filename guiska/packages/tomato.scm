(define-module (guiska packages tomato)
    #:use-module (ice-9 match)
    #:use-module (guix packages)
    #:use-module (guix download)
    #:use-module (guix gexp)
    #:use-module (guix git-download)
    #:use-module ((guix licenses) #:prefix license:)
    #:use-module (gnu packages)
    #:use-module (gnu packages mp3)
    #:use-module (gnu packages audio)
    #:use-module (gnu packages pulseaudio)
    #:use-module (gnu packages linux)
    #:use-module (gnu packages gtk)
    #:use-module (gnu packages cups)
    #:use-module (gnu packages glib)
    #:use-module (gnu packages xml)
    #:use-module (gnu packages fontutils)
    #:use-module (gnu packages gcc)
    #:use-module (gnu packages xdisorg)
    #:use-module (gnu packages gnome)
    #:use-module (gnu packages xorg)
    #:use-module (gnu packages gl)
    #:use-module (gnu packages nss)
    #:use-module (gnu packages databases)
    #:use-module (gnu packages compression)
    #:use-module (gnu packages base)
    #:use-module (gnu packages video)

    #:use-module (nongnu packages messaging)
    #:use-module (nongnu packages chrome)

    #:use-module (nonguix build-system binary)
    #:use-module (nonguix licenses)
    )

(define-public (make-electron-app name appname source version hash)
  
    (package
      (inherit element-desktop)
      (version version)
      (name name)
      (source
       (origin
	 (method url-fetch)
	 (uri
	  source)
	 (sha256
	  (base32 hash))))
      (arguments
       (list #:validate-runpath? #f ; TODO: fails on wrapped binary and included other files
             #:patchelf-plan
             #~`(( ,(string-append "lib/" appname name)
                   ("alsa-lib" "at-spi2-atk" "at-spi2-core" "atk" "cairo" "cups"
                    "dbus" "expat" "fontconfig-minimal" "gcc" "gdk-pixbuf" "glib"
                    "gtk+" "libdrm" "libnotify" "libsecret" "libx11" "libxcb"
                    "libxcomposite" "libxcursor" "libxdamage" "libxext" "libxfixes"
                    "libxi" "libxkbcommon" "libxkbfile" "libxrandr" "libxrender"
                    "libxtst" "mesa" "nspr" "pango" "zlib")))
             #:phases
             #~(modify-phases %standard-phases
		 (replace 'unpack
                   (lambda _
                     (invoke "ar" "x" #$source)
                     (invoke "tar" "xvf" "data.tar.xz")
                     (copy-recursively "usr/" ".")
                     ;; Use the more standard lib directory for everything.
                     (rename-file "opt/" "lib")
                     ;; Remove unneeded files.
                     (delete-file-recursively "usr")
                     (delete-file "control.tar.gz")
                     (delete-file "data.tar.xz")
                     (delete-file "debian-binary")
                     ;; Fix the .desktop file binary location.
                     (substitute* '(,(string-append "share/applications/" name ".desktop")) 
                       (((string-append "/opt/" appname))
			(string-append #$output "/lib/" appname)))))
		 (add-after 'install 'symlink-binary-file-and-cleanup
                   (lambda _
                     (delete-file (string-append #$output "/environment-variables"))
                     (mkdir-p (string-append #$output "/bin"))
                     (symlink (string-append #$output "/lib/" appname "/" name)
                              (string-append #$output "/bin/" name ))))
		 (add-after 'install 'wrap-where-patchelf-does-not-work
                   (lambda _
                     (wrap-program (string-append #$output "/lib/" appname "/" name)
                       `("FONTCONFIG_PATH" ":" prefix
			 (,(string-join
                            (list
                             (string-append #$(this-package-input "fontconfig-minimal") "/etc/fonts")
                             #$output)
                            ":")))
                       `("LD_LIBRARY_PATH" ":" prefix
			 (,(string-join
                            (list
                             (string-append #$(this-package-input "nss") "/lib/nss")
                             (string-append #$(this-package-input "eudev") "/lib")
                             (string-append #$(this-package-input "gcc") "/lib")
                             (string-append #$(this-package-input "mesa") "/lib")
                             (string-append #$(this-package-input "libxkbfile") "/lib")
                             (string-append #$(this-package-input "zlib") "/lib")
                             (string-append #$(this-package-input "libsecret") "/lib")
                             (string-append #$(this-package-input "sqlcipher") "/lib")
                             (string-append #$(this-package-input "libnotify") "/lib")
                             (string-append #$output "/lib/" appname)
                             #$output)
                            ":")))))))))))

(define bitwarden-version "2022.12.0")
(define-public bitwarden
  (make-electron-app "bitwarden" "Bitwarden"
		     (string-append
	 "https://github.com/bitwarden/clients/releases/download/desktop-v" bitwarden-version "/Bitwarden-" bitwarden-version "-amd64.deb") bitwarden-version "1qgszs607zr9d6yjl9xqpy2yjq2248mh38wz7ck796hqc7a0dr3m"))

(define whalebird-version "4.7.3")
(define-public whalebird
  (make-electron-app "whalebird" "Whalebird"
		     (string-append
		      "https://github.com/h3poteto/whalebird-desktop/releases/download/" whalebird-version "/Whalebird-" whalebird-version "-linux-x64.deb") whalebird-version "08550dmr9kzj8mm7dvhrvfw2wa8hnqqjn3dmvcgnia9g43cv7rjn"))


(define-public (make-vivaldi repo version hash)
  (let ((name (string-append "vivaldi-" repo))
         (appname "vivaldi"))
    (package
     (name name)
     (version version)
     (source (origin
               (method url-fetch)
               (uri
                (string-append
                 "https://downloads.vivaldi.com/" repo "/"
                 name "_" version "-1_amd64.deb"))
               (sha256
                (base32 hash))))
     (build-system binary-build-system)
     (arguments
      (list
        ;; almost 300MB, faster to download and build from Google servers
        #:substitutable? #f
        #:patchelf-plan
         #~(let ((patchelf-inputs
                   '("alsa-lib" "at-spi2-atk" "at-spi2-core" "atk" "cairo" "cups"
                     "dbus" "expat" "fontconfig-minimal" "gcc" "gdk-pixbuf" "glib"
                     "gtk" "libdrm" "libnotify" "libsecret" "libx11" "libxcb"
                     "libxcomposite" "libxcursor" "libxdamage" "libxext" "libxfixes"
                     "libxi" "libxkbcommon" "libxkbfile" "libxrandr" "libxrender"
                     "libxtst" "mesa" "nspr" "pango" "zlib" "ffmpeg"))
                 (path (string-append "opt/vivaldi/")))
             (map (lambda (file)
                    (cons (string-append path file) (list patchelf-inputs)))
                  '("vivaldi-bin"
                    "vivaldi-sandbox"
                    "chrome_crashpad_handler"
                    "libEGL.so"
                    "libGLESv2.so")))
        #:install-plan
         #~'(("opt/" "/share")
             ("usr/share/" "/share"))
        #:phases
         #~(modify-phases %standard-phases
             (add-after 'unpack 'unpack-deb
               (lambda* (#:key inputs #:allow-other-keys)
                 (invoke "ar" "x" #$source)
                 (invoke "rm" "-v" "control.tar.xz"
                                   "debian-binary"
                                   (string-append #$name "_"
                                                  #$version
                                                  "-1_amd64.deb"))
                 (invoke "tar" "xf" "data.tar.xz")
                 (invoke "rm" "-vrf" "data.tar.xz" "etc")))
             (add-before 'install 'patch-assets
               ;; Many thanks to
               ;; https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/browsers/google-chrome/default.nix
               (lambda _
                 (let* ((bin (string-append #$output "/bin"))
                        (share (string-append #$output "/share"))
                        (opt "./opt")
                        (usr/share "./usr/share")
                        (old-exe (string-append "/opt/vivaldi/" "vivaldi"))
                        (exe (string-append bin "/vivaldi")))
                   ;; This allows us to override CHROME_WRAPPER later.
                   (substitute* (string-append opt "/vivaldi/" "vivaldi")
                     (("CHROME_WRAPPER") "WRAPPER"))
                   (substitute* (string-append usr/share "/applications/" #$name ".desktop")
                     (("^Exec=.*") (string-append "Exec=" exe "\n")))
                   
                   (substitute* (string-append usr/share "/menu/vivaldi.menu")
                     (("/opt") share)
                     ((old-exe) exe))
                   #t)))
             (add-after 'install 'install-wrapper
              (lambda _
                (let* ((bin (string-append #$output "/bin"))
                       (exe (string-append bin "/vivaldi"))
                       (share (string-append #$output "/share"))
                       (chrome-target (string-append share "/vivaldi/" #$appname)))
                  (mkdir-p bin)
                  (symlink chrome-target exe)
                  (wrap-program exe
                    `("FONTCONFIG_PATH" ":" prefix
                      (,(string-join
                         (list
                          (string-append #$(this-package-input "fontconfig-minimal") "/etc/fonts")
                          #$output)
                         ":")))
                    `("LD_LIBRARY_PATH" ":" prefix
                      (,(string-join
                         (list
                          (string-append #$(this-package-input "nss") "/lib/nss")
                          (string-append #$(this-package-input "eudev") "/lib")
                          (string-append #$(this-package-input "gcc") "/lib")
                          (string-append #$(this-package-input "mesa") "/lib")
                          (string-append #$(this-package-input "libxkbfile") "/lib")
                          (string-append #$(this-package-input "zlib") "/lib")
                          (string-append #$(this-package-input "libsecret") "/lib")
                          (string-append #$(this-package-input "sqlcipher") "/lib")
                          (string-append #$(this-package-input "libnotify") "/lib")
                          (string-append #$(this-package-input "libdrm") "/lib")
                          (string-append #$(this-package-input "pipewire") "/lib")
                          #$output)
                         ":")))
                    '("CHROME_WRAPPER" = (#$appname)))))))))
     (native-inputs (list tar))
     (inputs
      (list alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            eudev
            expat
            fontconfig
            `(,gcc "lib")
            glib
            gtk
            libdrm
            libnotify
            librsvg
            libsecret
            libx11
            libxcb
            libxcomposite
            libxcursor
            libxdamage
            libxext
            libxfixes
            libxi
            libxkbcommon
            libxkbfile
            libxrandr
            libxrender
            libxtst
            mesa
            nspr
            nss
            pango
            pipewire-0.3
            sqlcipher
            zlib
	    ffmpeg))
     (synopsis  "Freeware web browser")
     (supported-systems '("x86_64-linux"))
     (description "cringe bloat proprietary web thing")
     (home-page "https://www.google.com/chrome/")
     (license (nonfree "https://www.google.com/intl/en/chrome/terms/")))))

(define-public vivaldi-stable
  (make-vivaldi "stable" "5.6.2867.36" "1bnxdylr3bh7q1j1559lmh0rigaxh6rcmsjwc63myvpz36jyjdbm"))
