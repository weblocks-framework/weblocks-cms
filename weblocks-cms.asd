;;;; weblocks-cms.asd

(asdf:defsystem #:weblocks-cms
  :description "A CMS for Weblocks"
  :author "Olexiy Zamkoviy <olexiy.z@gmail.com>"
  :license "LLGPL"
  :version "0.0.5"
  :depends-on (#:weblocks
               #:weblocks-stores
               #:weblocks-utils 
               #:weblocks-twitter-bootstrap-application 
               #:cl-fad 
               #:closure-html 
               #:cxml 
               #:cl-ppcre)
  :components ((:file "package")
               (:file "weblocks-cms" :depends-on ("field-description" "model-description" "package" "tinymce-textarea-presentation" "util" "get-view-field" "get-table-view-field"))
               (:file "field-description" :depends-on ("package"))
               (:file "model-description" :depends-on ("package" "field-description"))
               (:file "tinymce-textarea-presentation" :depends-on ("package"))
               (:file "util")
               (:file "get-view-field")
               (:file "get-table-view-field")))

