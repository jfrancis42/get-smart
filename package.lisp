;;;; package.lisp

(defpackage #:get-smart
  (:use #:cl)
  (:import-from :json
		:encode-json-to-string
		:decode-json-from-string)
  (:import-from :jsown
		:pretty-json
		:pprint-json)
  (:import-from :split-sequence
		:split-sequence)
  (:import-from :alexandria
                :flatten)
  (:import-from :jeffutils
		:remove-duplicate-strings
		:clean-string
		:string-or-nil
		:file-string
		:histogram
                :cdr-assoc)
  (:export :load-api-key
           :list-models
	   :list-language-models
           :list-image-generation-models
	   :get-user-balance
           :tokenize
	   :get-model
           :get-language-model
	   :get-image-generation-model
           :get-api-key-info
	   :ask-chat
	   :ask-reason
	   :*assistant*)
)
