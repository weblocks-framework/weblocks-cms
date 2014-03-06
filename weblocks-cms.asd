;;;; weblocks-cms.asd

(asdf:defsystem #:weblocks-cms
  :description "A CMS for Weblocks"
  :author "Olexiy Zamkoviy <olexiy.z@gmail.com>"
  :license "LLGPL"
  :version "0.2.16"
  :depends-on (#:weblocks
               #:weblocks-stores
               #:weblocks-utils 
               #:weblocks-twitter-bootstrap-application 
               #:cl-fad 
               #:closure-html 
               #:cxml 
               #:cl-ppcre 
               #:weblocks-tree-widget 
               #:alexandria 
               #:weblocks-bootstrap-typeahead-presentation 
               #:weblocks-bootstrap-date-entry-presentation 
               #:weblocks-ajax-file-upload-presentation 
               #:yaclml)
  :components ((:file "package")
               (:file "weblocks-cms" :depends-on ("field-description" "model-description" "package" "tinymce-textarea-presentation" "util" "get-view-field" "get-table-view-field" "super-admin-interface" "tree-edit-model" "tree-edit-widget"))
               (:file "field-description" :depends-on ("package"))
               (:file "model-description" :depends-on ("package" "field-description"))
               (:file "tinymce-textarea-presentation" :depends-on ("package"))
               (:file "codemirror-presentation" :depends-on ("package"))
               (:file "util" :depends-on ("package"))
               (:file "get-view-field" :depends-on ("package"))
               (:file "get-table-view-field" :depends-on ("package"))
               (:file "super-admin-interface" :depends-on ("field-description" "model-description" "yaclml-syntax-improvement" "new-page-editable-gridedit"))
               (:file "tree-edit-model" :depends-on ("package"))
               (:file "tree-edit-widget" :depends-on ("package"))
               (:file "yaclml-syntax-improvement" :depends-on ("package"))
               (:file "new-page-editable-gridedit" :depends-on ("package"))))

