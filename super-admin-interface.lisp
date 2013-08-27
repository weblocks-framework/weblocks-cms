(in-package :weblocks-cms)

(eval `(defview field-form-view (:type form :inherit-from '(:scaffold field-description))
                (title :requiredp t)
                (name :requiredp t 
                      :reader (lambda (item)
                                (string-downcase (slot-value item 'name)))
                      :writer (lambda (value item)
                                (setf (slot-value item 'name) (alexandria:make-keyword (string-upcase value)))))
                (type :present-as (radio :choices '(("Choice yes/no" . boolean)
                                                    ("Integer" . integer) 
                                                    ("String" . string)
                                                    ("Few lines of text" . textarea)
                                                    ("Text editor" . editor-textarea)
                                                    ("Date and time" . datetime)
                                                    ("Single choice" . single-choice)
                                                    ("Multiple choices" . multiple-choices)
                                                    ("File" . file)
                                                    ("Single relation" . single-relation)))
                      :reader (lambda (item)
                                (string-downcase (slot-value item 'type))) 
                      :writer (lambda (value item)
                                (setf (slot-value item 'type) (alexandria:make-keyword (string-upcase value)))))
                (type-data :present-as textarea)
                ,(related-record-field 'model-description #'model-description-title (list :requiredp t) :field-name 'model)))

(defun weblocks-cms-access-granted ()
  "Override this function for using login logic"
  t)

(defun/cc init-super-admin-session (root)
  (when (weblocks-cms-access-granted)
    (do-page 
      (make-navigation 
        "toplevel"
        (list "Models" 
              (make-instance 
                'gridedit 
                :data-class 'model-description 
                :view (defview nil (:type table :inherit-from '(:scaffold model-description))
                               (name :present-as text 
                                     :reader (lambda (item)
                                               (string-downcase (model-description-name item)))))
                :item-form-view 
                (defview nil (:type form :inherit-from '(:scaffold model-description))
                         (name :requiredp t 
                               :reader (lambda (item)
                                         (string-downcase (slot-value item 'name)))
                               :writer (lambda (value item)
                                         (setf (slot-value item 'name) (alexandria:make-keyword (string-upcase value))))))) nil)
        (list "Models Fields"
              (make-instance 
                'gridedit 
                :data-class 'field-description 
                :view (defview nil (:type table :inherit-from '(:scaffold field-description))
                               (model :present-as text 
                                      :reader (lambda (item)
                                                (format nil "~A (~A)" 
                                                        (model-description-title (field-description-model item))
                                                        (string-downcase (model-description-name (field-description-model item)))))))
                :item-form-view 'field-form-view) "fields")
        (list "Preview Models"
              (lambda (&rest args)
                (save-schema)
                (setf *current-schema* (read-schema))

                (regenerate-model-classes)
                (loop for i in *current-schema* do 
                      (render-widget 
                        (make-quickform (get-model-form-view (getf i :name) :display-buttons nil)))))
              "forms-preview")
        :navigation-class 'bootstrap-navbar-navigation))))
