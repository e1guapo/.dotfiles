(define-module (packages nerd-fonts)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system font)
  #:use-module ((guix licenses) #:prefix license:))

(define-public font-dejavu-sans-mono-nerd
  (package
    (name "font-dejavu-sans-mono-nerd")
    (version "3.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ryanoasis/nerd-fonts/releases/download/v"
             version "/DejaVuSansMono.tar.xz"))
       (sha256
        (base32 "1k16n9klb5j3xs0dvbin3gb8i7cjaflxnkrjgwmr4y4k3yfgyn0f"))))
    (build-system font-build-system)
    (home-page "https://www.nerdfonts.com/")
    (synopsis "DejaVu Sans Mono patched with Nerd Fonts glyphs")
    (description
     "Nerd Fonts patched build of DejaVu Sans Mono.  Adds Powerline,
Devicons, Font Awesome, and other icon glyphs while keeping DejaVu Sans
Mono's base letterforms.  Provides three variants: @code{DejaVuSansM Nerd
Font} (variable-width icons), @code{DejaVuSansM Nerd Font Mono} (strict
single-cell icons, recommended for terminals), and @code{DejaVuSansM Nerd
Font Propo} (proportional).")
    (license (license:x11-style "http://dejavu-fonts.org/"))))
