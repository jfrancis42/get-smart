;;;; get-smart.lisp

(in-package #:get-smart)

(defparameter *api-key* nil)
(defparameter *provider* nil)

;; (load-api-key :grok "~/crypt/grok_api_key.txt")
;; (load-api-key :deepseek "~/crypt/deepseek_api_key.txt")

(defparameter *assistant* "You are a helpful assistant.")
(defparameter *network-engineer* "You are an expert in IP networking and server operating systems.")

; error codes: https://api-docs.deepseek.com/quick_start/error_codes

;; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; https://stackoverflow.com/questions/27679494/how-to-output-false-while-using-cl-json

(defclass json-false ()
  ())

(defmethod json:encode-json ((object json-false) &optional stream)
  (princ "false" stream)
  nil)

(defvar *json-false* (make-instance 'json-false))

(defun json-bool (val)
  (if val t *json-false*))

(defun json-bool-handler (token)
  (or (string= token "true")
      (and (string= token "false") *json-false*)))

(defmacro preserving-json-boolean (opts &body body)
  (declare (ignore opts))
  `(let ((json:*boolean-handler* #'json-bool-handler))
     ,@body))

;; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

(defun load-api-key (provider file)
  "Load your API key and set the provider associated with it."
  (setf *api-key* (clean-string (file-string file)))
  (setf *provider* provider))

(defun provider-uri ()
  "Return the appropriate base URI for the selected *provider*."
  (cond
    ((equal :grok *provider*) "https://api.x.ai/v1/")
    ((equal :deepseek *provider*) "https://api.deepseek.com/v1/")
    (t nil)))

(defun provider-model (model)
  "Return the appropriate model name for the desired mode for the
selected *provider*."
  (cond
    ((equal :grok *provider*)
     (cond ((equal :chat model) "grok-2-latest")
	   ((equal :reason model) "grok-2-latest")
	   ((equal :image model) "grok-2-image-1212")
	   ((equal :vision model) "grok-2-vision-1212")
	   (t nil)))
    ((equal :deepseek *provider*)
     (cond ((equal :chat model) "deepseek-chat")
	   ((equal :reason model) "deepseek-reasoner")
	   ((equal :image model) nil)
	   ((equal :vision model) nil)
	   (t nil)))
    (t nil)))    

(defun call-api (uri method &optional (payload nil))
  "Call the API."
  (let ((result (if payload
		    (drakma:http-request
		     (concatenate 'string
				  (provider-uri)
				  uri)
                     :method method
		     :accept "application/json"
                     :content-type "application/json"
		     :additional-headers
		     (list (cons "Authorization" (concatenate 'string "Bearer " *api-key*)))
		     :content payload)
		    (drakma:http-request
		     (concatenate 'string
				  (provider-uri)
				  uri)
                     :method method
		     :accept "application/json"
                     :content-type "application/json"
		     :additional-headers
		     (list (cons "Authorization" (concatenate 'string "Bearer " *api-key*)))))))
    (if (> (length result) 0)
        (json:decode-json-from-string
	 (babel:octets-to-string 
          (nth-value 0 result)))
        nil)))

(defun model-has-method (models)
  "Only runs for the models that provide a given method."
  (member *provider* models :test #'equal))

(defun list-models ()
  "List the valid models for this provider."
  (when (model-has-method (list :grok :deepseek))
    (call-api "models" :get)))

(defun list-language-models ()
  "List the valid language models for this provider."
  (when (model-has-method (list :grok))
    (call-api "language-models" :get)))

(defun list-image-generation-models ()
  "List the valid image generation models for this provider."
  (when (model-has-method (list :grok))
    (call-api "image-generation-models" :get)))

(defun get-user-balance ()
  "How much money do I have left?"
  (when (model-has-method (list :deepseek))
    (call-api "user/balance" :get)))

(defun tokenize (stuff)
  "Tokenize stuff and give me the results."
  (when (model-has-method (list :grok))
    (call-api "tokenize-text" :post
	      (encode-json-to-string (list (cons :text stuff)
					   (cons :model (provider-model :chat)))))))

(defun get-model (model)
  "Retrieve info about the specified model."
  (when (model-has-method (list :grok))
    (call-api (concatenate 'string "models/" model) :get)))

(defun get-language-model (model)
  "Retrieve info about the specified language model."
  (when (model-has-method (list :grok))
    (call-api (concatenate 'string "language-models/" model) :get)))

(defun get-image-generation-model (model)
  "Retrieve info about the specified image generation model."
  (when (model-has-method (list :grok))
    (call-api (concatenate 'string "image-generation-models/" model) :get)))

(defun get-api-key-info ()
  "Retrieve info about the API key in use."
  (when (model-has-method (list :grok))
    (call-api "api-key" :get)))

(defun temperature (&optional (temp :default))
  (cond
    ((equal :coding temp) 0.0)
    ((equal :math temp) 0.0)
    ((equal :data-cleaning temp) 1.0)
    ((equal :data-analysis temp) 1.0)
    ((equal :general-conversation temp) 1.3)
    ((equal :translation temp) 1.3)
    ((equal :creative-writing temp) 1.5)
    ((equal :poetry temp) 1.5)
    ((equal :default temp) 1.0)
    (t temp)))

(defun make-message (role content)
  (list (cons "role" role)
	(cons "content" content)))

(defun payload (messages &key (model :chat) (temperature :default) (presence-penalty 0)
			   (response-format :text) (top-p 1) stream freq-penalty stop
			   max-tokens logprobs top-logprobs)
  (remove nil
	  (list
	   (cons :messages messages)
	   (cons "model" (provider-model model))
	   (when freq-penalty
	     (cons "frequency_penalty" freq-penalty))
	   (when max-tokens
	     (cons "max_tokens" max-tokens))
	   (when presence-penalty
	     (cons "presence_penalty" presence-penalty))
	   (list "response_format" (cons :type
					 (cond ((equal :text response-format) "text")
					       ((equal :json response-format) "json_object"))))
	   (cons "stop" stop)
	   (cons "stream" (if stream stream *json-false*))
	   ;; TODO: stream_options
	   (cons "temperature" (temperature temperature))
	   (cons "top_p" top-p)
	   ;; TODO: tools
	   ;; TODO: tool_choice
	   (cons "logprobs" (if (or logprobs top-logprobs) t *json-false*))
	   (cons "top_logprobs" top-logprobs)
	   )))

(defun ask-chat (who-am-i what
		 &key
		   attach
		   (max-tokens 4096)
		   (presence-penalty 0.0)
		   (freq-penalty 0.0)
		   (response-format :text)
		   (logprobs nil)
		   (top-logprobs nil)
		   (temp :general-conversation))
  (when (model-has-method (list :grok :deepseek))
    (call-api "chat/completions"
	      :post
	      (json:encode-json-to-string
	       (payload (list (make-message "system" who-am-i)
			      (if attach
				  (make-message "user"
						(format nil "~A~%~%~A~%"
							what
							(file-string attach)))
				  (make-message "user" what)))
			:max-tokens max-tokens
			:presence-penalty presence-penalty
			:freq-penalty freq-penalty
			:response-format response-format
			:logprobs logprobs
			:top-logprobs top-logprobs
			:model :chat
			:temperature temp)))))

(defun ask-reason (who-am-i what
		   &key
		     attach
		     (max-tokens 4096)
		     (presence-penalty 0.0)
		     (freq-penalty 0.0)
		     (response-format :text)
		     (logprobs nil)
		     (top-logprobs nil)
		     (temp :default))
  (when (model-has-method (list :grok :deepseek))
    (call-api "chat/completions"
	      :post
	      (json:encode-json-to-string
	       (payload (list (make-message "system" who-am-i)
			      (if attach
				  (make-message "user"
						(format nil "~A~%~%~A~%"
							what
							(file-string attach)))
				  (make-message "user" what)))
			:max-tokens max-tokens
			:presence-penalty presence-penalty
			:freq-penalty freq-penalty
			:response-format response-format
			:logprobs logprobs
			:top-logprobs top-logprobs
			:model :reason
			:temperature temp)))))

;; (jeff:cdr-assoc :message (first (jeff:cdr-assoc :choices *answer*)))

;;; Local Variables:
;;; mode: Lisp
;;; coding: utf-8
;;; End:
