;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

(load! "work-packages" doom-user-dir t)

(package! jq-mode)

                                        ;(package! bpftrace-mode
                                        ;  :recipe (:local-repo "bpftrace-mode"))

(package! tera-mode
  :recipe (:host github :repo "svavs/tera-mode")
  :pin "cf3e9a2d86853eb2162b8c2160cdf57d7ca6a442")

                                        ;(package! lalrpop-mode
                                        ;  :recipe (:local-repo "lalrpop-mode"))
                                        ;(package! llvm-mode
                                        ;  :recipe (:local-repo "llvm-mode"))

(package! org-super-agenda)

(package! jsonnet-mode
  :recipe (:host github :repo "tminor/jsonnet-mode")
  :pin "00229c2f04bb4be26686eb325303865dac3cabf8")

;; (package! shrink-path :disable t)

(package! undo-fu-session
  :recipe (:host github :repo "emacsmirror/undo-fu-session")
  :pin "d90d42ddba8fa42ef5dc109196545caeabb42b75")
(package! undo-fu
  :recipe (:host github :repo "emacsmirror/undo-fu")
  :pin "399cc12f907f81a709f9014b6fad0205700d5772")
(package! ron-mode
  :recipe (:host github :repo "emacsmirror/ron-mode")
  :pin "c5e0454b9916d6b73adc15dab8abbb0b0a68ea22")

                                        ;(package! tree-sitter-indent
                                        ;  :recipe (:host github :repo "emacs18/tree-sitter-indent.el")
                                        ;  :pin "4ef246db3e4ff99f672fe5e4b416c890f885c09e")

                                        ;(package! rhai-mode
                                        ;  :recipe (:local-repo "rhai-mode"))


(package! graphviz-dot-mode
  :recipe (:host github :repo "ppareit/graphviz-dot-mode")
  :pin "45338857d0ad62c0f9dee392c23b9ba341225c7f")

                                        ;(package! wit-mode
                                        ;  :recipe (:local-repo "wit-mode"
                                        ;           :build nil))

;; (package! asana-api
;;   :recipe (:local-repo "asana-api" :build nil))

(package! gptel
  :recipe (:host github :repo "karthink/gptel")
  :pin "3722942363b26befd35e9c259de3f42e9ed704a7")


;; javascript module broken without this
(package! rjsx-mode)

(package! key-chord)

(package! org-modern
  :recipe (:host github :repo "minad/org-modern")
  :pin "1723689710715da9134e62ae7e6d41891031813c")

(package! mermaid-mode
  :recipe (:host github :repo "abrochard/mermaid-mode")
  :pin "e74d4da7612c7a88e07f9dd3369e3b9fd36f396c")

(package! ob-mermaid
  :recipe (:host github :repo "arnm/ob-mermaid")
  :pin "372c2d91d3cdba5da9f7ac23e7bce7a0b3b46862")



                                        ;(package! ox-hugo
                                        ;	  :recipe (:host github :repo "kaushalmodi/ox-hugo")
                                        ;	  :pin "e3365cb4e65c1853d8838b863a21546bbd9e0990")
                                        ;(package! ox-zola
                                        ;	  :recipe (:host github :repo "gicrisf/ox-zola")
                                        ;	  :pin "6e83a58f248f8c6ad2fa8f436b619c94f736b41f")

(package! nushell-mode :recipe (:host github :repo "mrkkrp/nushell-mode")
  :pin "155acf85d0ab26dc86e248452df00f7820e775ed")

(package! llvm-mode
  :recipe (:host github :repo "nverno/llvm-mode")
  :pin "9741e5391ea711474474d8d4aacd5abaae2ba501")


;; (package! silicon
;;   :recipe (:host github :repo "iensu/silicon-el")
;;   :pin "f404ca270ffcb345444b1c488051723985a53807")
;;(package! silicon
;;  :recipe (:local-repo "silicon-el"
;;           :build (:not compile)))

(package! hoon-mode
  :recipe (:host github
           :repo "urbit/hoon-mode.el"
           :files (:defaults "*.json"))
  :pin "5369ecec3cd154628cb23cf80d65c007bd940c70")
