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
