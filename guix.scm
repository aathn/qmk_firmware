(use-modules
 (guix packages)
 (guix utils)
 (guix build-system trivial)
 (gnu packages avr)
 (gnu packages cross-base)
 (gnu packages gcc)
 (gnu packages embedded)
 (gnu packages flashing-tools))

;; downgraded version of avr-gcc, copied from (gnu packages avr)
(define avr-gcc
  (let ((xgcc (cross-gcc "avr" #:xgcc gcc-8 #:xbinutils avr-binutils)))
    (package
      (inherit xgcc)
      (name "avr-gcc")
      (arguments
       (substitute-keyword-arguments (package-arguments xgcc)
         ((#:phases phases)
          `(modify-phases ,phases
             (add-after 'set-paths 'augment-CPLUS_INCLUDE_PATH
               (lambda* (#:key inputs #:allow-other-keys)
                 (let ((gcc (assoc-ref inputs  "gcc")))
                   ;; Remove the default compiler from CPLUS_INCLUDE_PATH to
                   ;; prevent header conflict with the GCC from native-inputs.
                   (setenv "CPLUS_INCLUDE_PATH"
                           (string-join
                            (delete (string-append gcc "/include/c++")
                                    (string-split (getenv "CPLUS_INCLUDE_PATH")
                                                  #\:))
                            ":"))
                   (format #t
                           "environment variable `CPLUS_INCLUDE_PATH' changed to ~a~%"
                           (getenv "CPLUS_INCLUDE_PATH"))
                   #t)))
             ;; Without a working multilib build, the resulting GCC lacks
             ;; support for nearly every AVR chip.
             (add-after 'unpack 'fix-genmultilib
               (lambda _
                 ;; patch-shebang doesn't work here because there are actually
                 ;; several scripts inside this script, each with a #!/bin/sh
                 ;; that needs patching.
                 (substitute* "gcc/genmultilib"
                   (("#!/bin/sh") (string-append "#!" (which "sh"))))
                 #t))))
         ((#:configure-flags flags)
          `(delete "--disable-multilib" ,flags))))
      (native-search-paths
       (list (search-path-specification
              (variable "CROSS_C_INCLUDE_PATH")
              (files '("avr/include")))
             (search-path-specification
              (variable "CROSS_CPLUS_INCLUDE_PATH")
              (files '("avr/include")))
             (search-path-specification
              (variable "CROSS_OBJC_INCLUDE_PATH")
              (files '("avr/include")))
             (search-path-specification
              (variable "CROSS_OBJCPLUS_INCLUDE_PATH")
              (files '("avr/include")))
             (search-path-specification
              (variable "CROSS_LIBRARY_PATH")
              (files '("avr/lib")))))
      (native-inputs
       `(("gcc" ,gcc-8)
         ,@(package-native-inputs xgcc))))))

(package
 (name "qmk-deps")
 (version "0.1.0")
 (source #f)
 (build-system trivial-build-system)
 (native-inputs
  (list
   arm-none-eabi-nano-toolchain-7-2018-q2-update
   avrdude
   avr-gcc
   dfu-programmer
   dfu-util))
 (synopsis "")
 (description "")
 (home-page "")
 (license #f))
