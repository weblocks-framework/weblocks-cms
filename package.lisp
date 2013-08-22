;;;; package.lisp

(defpackage #:weblocks-cms
  (:use #:cl #:weblocks #:weblocks-utils #:weblocks-twitter-bootstrap-application)
  (:export 
    #:weblocks-cms 
    #:model-description 
    #:field-description 
    #:*upload-directory* 
    #:*models-package*
    #:*current-schema
    #:regenerate-model-classes 
    #:read-schema 
    #:save-schema 
    #:dump-schema 
    #:models-gridedit-widgets-for-navigation 
    #:weblocks-cms-access-granted))

