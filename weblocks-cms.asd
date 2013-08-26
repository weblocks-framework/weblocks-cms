;;;; weblocks-cms.asd

(asdf:defsystem #:weblocks-cms
  :description "A CMS for Weblocks"
  :author "Olexiy Zamkoviy <olexiy.z@gmail.com>"
  :license "LLGPL"
  :version "0.1.0"
  :depends-on (#:weblocks
               #:weblocks-stores
               #:weblocks-utils 
               #:weblocks-twitter-bootstrap-application 
               #:cl-fad 
               #:closure-html 
               #:cxml 
               #:cl-ppcre 
               #:weblocks-tree-widget 
               #:alexandria)
  :components ((:file "package")
               (:file "weblocks-cms" :depends-on ("field-description" "model-description" "package" "tinymce-textarea-presentation" "util" "get-view-field" "get-table-view-field" "super-admin-interface" "tree-edit-model" "tree-edit-widget"))
               (:file "field-description" :depends-on ("package"))
               (:file "model-description" :depends-on ("package" "field-description"))
               (:file "tinymce-textarea-presentation" :depends-on ("package"))
               (:file "util" :depends-on ("package"))
               (:file "get-view-field" :depends-on ("package"))
               (:file "get-table-view-field" :depends-on ("package"))
               (:file "super-admin-interface" :depends-on ("field-description" "model-description"))
               (:file "tree-edit-model" :depends-on ("package"))
               (:file "tree-edit-widget" :depends-on ("package"))))

