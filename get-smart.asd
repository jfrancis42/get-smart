;;;; get-smart.asd

(asdf:defsystem #:get-smart
  :description "A library for using the common AGI/LLM APIs."
  :author "Jeff Francis <jeff@gritch.org>"
  :license "MIT, see file LICENSE"
  :depends-on (#:drakma
	       #:babel
	       #:jeffutils
               #:cl-json
	       #:jsown-utils
               #:local-time)
  :serial t
  :components ((:file "package")
               (:file "get-smart")
	       ))
