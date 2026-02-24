;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (guix gexp)
             (gnu home services)
             (gnu home services dotfiles)
             (gnu home services shells)
             (gnu home services xdg))

(define flameshot-shortcuts-desktop
  (plain-file
   "set-flameshot-shortcuts.desktop"
   (string-append
    "[Desktop Entry]\n"
    "Type=Application\n"
    "Version=1.0\n"
    "Name=Set Flameshot Shortcuts\n"
    "Comment=Ensure PrintScreen bindings target Flameshot.\n"
    "Exec=sh -c '$HOME/scripts/set_flameshot_shortcuts.sh'\n"
    "X-GNOME-Autostart-enabled=true\n")))

(define xfce-power-config-desktop
  (plain-file
   "configure-xfce-power.desktop"
   (string-append
    "[Desktop Entry]\n"
    "Type=Application\n"
    "Version=1.0\n"
    "Name=Configure XFCE Power Manager\n"
    "Comment=Set XFCE Power Manager settings for logind lid handling.\n"
    "Exec=sh -c '$HOME/scripts/configure_xfce_power.sh'\n"
    "X-GNOME-Autostart-enabled=true\n")))

(define bash-config-dir
  (string-append (dirname (current-filename)) "/../../files/.bash_config_files/"))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list "meld"

                        ;; uncomment to try with guix container
                        ;; "diffutils"
                        ;; "coreutils"
                        ;; "bash"

                        ;; android stuff
                        "git-repo"

                        ;; RS BBN access
                        "keepassxc"

                        "imhex"
                        "imhex-pattern-language"
                        "binwalk"
                        "qemu"

                        "simple-scan"
                        "sane-airscan"
                        "sane-backends"

                        "ranger"
                        "util-linux"
                        "gdb-multiarch"
                        "clang"
                        "llvm"
                        "cloc"
                        "strace"
                        "tree"
                        "nmap"
                        "flameshot"
                        "imagemagick"
                        "cifs-utils"
                        "node"
                        "openjdk@23.0.2"
                        "gradle"
                        "git-lfs" ;; uncomment when not broken (ruby-activesupport test failing)
                        "gnupg"
                        "git"
                        "direnv"
                        "cmake"
                        "texlive"
                        "xss-lock"
                        "pasystray"
                        "fontconfig"
                        "slirp4netns"
                        "tk"
                        "python"
                        "python-virtualenv"
                        "python-packaging"
                        "texlive-inconsolata-nerd-font"
                        "universal-ctags"
                        "curl"
                        "nss-certs"
                        "simg2img"
                        "opam"
                        "vim-full"
                        "inotify-tools"
                        "xclip"
                        "make"
                        "file"
                        "libbsd"
                        "libtool"
                        "libffi"
                        "xz"
                        "ncurses"
                        "sqlite"
                        "readline"
                        "file"
                        "bzip2"
                        "lbzip2"
                        "zlib"
                        "lzlib"
                        "openssl"
                        "pkg-config"
                        "libxcrypt"
                        "glibc-locales")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services (list (simple-service 'custom-env-vars
                                  home-environment-variables-service-type
                                  (append '(("PATH" . "/var/lib/flatpak/exports/bin:$PATH")
                                            ("PATH" . "$HOME/.local/share/flatpak/exports/bin:$PATH")

                                            ;; Android tools installed with Android Studio.
                                            ("PATH" . "$HOME/Android/Sdk/build-tools/36.1.0:$PATH")
                                            ("PATH" . "$HOME/Android/Sdk/platform-tools/:$PATH")

                                            ;; Ghidra
                                            ("PATH" . "/opt/ghidra_11.4.2_PUBLIC:$PATH")

                                            ("PATH" . "$HOME/.local/bin:$PATH")
                                            ("PATH" . "$HOME/bin:$PATH"))

                                          '(("GHIDRA_INSTALL_DIR" . "/opt/ghidra_11.4.2_PUBLIC")

                                            ;; Android
                                            ("SCRCPY_PATH" .  "/home/dennis/data/tools/scrcpy-linux-x86_64-v3.3.3")
                                            ("ANDROID_SDK_ROOT" .  "/home/dennis/Android/Sdk")

                                            ;; Ensure Python picks up Guix-provided site-packages.
                                            ("PYTHONPATH" . "$GUIX_PYTHONPATH${PYTHONPATH:+:}$PYTHONPATH"))

                                            ;; for just-every/code - open source fork of codex cli
                                            ;; We change the default since VS Code already uses ~/.code
                                            ;;("CODE_HOME" . "$HOME/.every-code"))

                                          '(("EDITOR" . "vim")
                                            ("VISUAL" . "vim")
                                            ("HISTSIZE" . "10000")
                                            ;; don't put lines starting with space in the history.
                                            ;; See bash(1) for more options
                                            ("HISTCONTROL" . "ignorespace"))
                                          '(("XCURSOR_PATH" . "$HOME/.guix-home/profile/share/icons:/usr/share/icons:$HOME/.icons")
                                            ("XCURSOR_SIZE" . "48")
                                            ("XCURSOR_THEME" . "Adwaita")
                                            ("GDK_DPI_SCALE" . "1.25"))))
                  (service home-bash-service-type
                           (home-bash-configuration
                            (aliases '(
                                       ("claude" . "npx -y @anthropic-ai/claude-code")
                                       ("codex" . "npx -y @openai/codex@latest")
                                       ("every-code" . "npx -y @just-every/code")
                                       ("l" . "ls -CF")
                                       ("la" . "ls -A")
                                       ("ll" . "ls -alF")))
                            (bashrc
                              (list (local-file (string-append bash-config-dir "base.bashrc"))
                                    (local-file (string-append bash-config-dir "bash-prompt.bashrc"))
                                    (local-file (string-append bash-config-dir "conda.bashrc"))
                                    (local-file (string-append bash-config-dir "direnv.bashrc"))
                                    (local-file (string-append bash-config-dir "flatpak.bashrc"))
                                    (local-file (string-append bash-config-dir "ssh-agent.bashrc"))
                                    (local-file (string-append bash-config-dir "adb.bashrc"))
                                    (local-file (string-append bash-config-dir "uv.bashrc"))))
                            (bash-profile (list (local-file (string-append bash-config-dir "bash_profile.bashrc"))))
                            (bash-logout (list (local-file (string-append bash-config-dir "bash_logout.bashrc"))))))
                  (service home-dotfiles-service-type
                           (home-dotfiles-configuration
                            (directories '("../../files"))
                            ;; We are explicit with the excluded list to remove all the .git stuff.
                            (excluded '(".*~" ".*\\.swp"))))
                  (simple-service 'autostart-configs
                                  home-xdg-configuration-files-service-type
                                  (list
                                   `("autostart/set-flameshot-shortcuts.desktop"
                                     ,flameshot-shortcuts-desktop)
                                   `("autostart/configure-xfce-power.desktop"
                                     ,xfce-power-config-desktop))))))
