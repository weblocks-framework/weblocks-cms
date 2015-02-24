(in-package :weblocks-cms)

(defun descr-title-alias (obj)
  (model-description-title obj))

(defun field-form-view ()
  (eval `(defview field-form-view (:type form :inherit-from '(:scaffold field-description))
                  (title :requiredp t)
                  (name :requiredp t 
                        :reader (lambda (item)
                                  (when (slot-value item 'name)
                                    (string-downcase (slot-value item 'name))))
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
                                                      ("Single relation" . single-relation)
                                                      ("Custom field" . custom)))
                        :reader (lambda (item)
                                  (string-downcase (slot-value item 'type))) 
                        :writer (lambda (value item)
                                  (setf (slot-value item 'type) (alexandria:make-keyword (string-upcase value)))))
                  (type-data :present-as textarea)
                  ,(related-record-field 'model-description #'descr-title-alias (list :requiredp t) :field-name 'model))))

(defun weblocks-cms-access-granted ()
  "Override this function for using login logic"
  t)

(defmacro def-simple-tag-with-any-attributes (name)
  "Convience macro for defing tags which accept any kind of attribute
   and just wrap the body in an xml tag."
  `(yaclml:deftag ,name (&allow-other-attributes other-attributes &body body)
     (progn
       (yaclml:emit-open-tag ,(string-downcase (string name)) other-attributes)
       (yaclml:emit-body body)
       (yaclml:emit-close-tag ,(string-downcase (string name))))))

(defmacro allow-any-attributes-for-tag (tag)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (def-simple-tag-with-any-attributes ,tag)))

(defmacro allow-any-attributes-for-self-closing-tag (tag)
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (yaclml::def-simple-xtag ,tag)))

(allow-any-attributes-for-tag <:button)

(defun/cc init-super-admin-session (root)
  (when (weblocks-cms-access-granted)
    (do-page 
      (make-instance 'composite 
                     :widgets (list 
                                (lambda (&rest args)
                                  (with-yaclml 
                                    (<br)))
                                (make-navbar-selector 
                                  "toplevel"
                                  (list "Models" 
                                        (let* ((grid (make-instance 
                                                       'popover-gridedit 
                                                       :data-class 'model-description 
                                                       :view (defview nil (:type table :inherit-from '(:scaffold model-description))
                                                                      (name :present-as text 
                                                                            :allow-sorting-p t
                                                                            :reader (lambda (item)
                                                                                      (when (model-description-name item)
                                                                                        (string-downcase (model-description-name item))))))
                                                       :item-form-view 
                                                       (defview nil (:type form :inherit-from '(:scaffold model-description))
                                                                (name :requiredp t 
                                                                      :reader (lambda (item)
                                                                                (when (slot-value item 'name)
                                                                                  (string-downcase (slot-value item 'name))))
                                                                      :writer (lambda (value item)
                                                                                (setf (slot-value item 'name) (alexandria:make-keyword (string-upcase value))))))))
                                               (action-links (lambda (&rest args)
                                                               (with-yaclml
                                                                 (<h3 "Actions:")
                                                                 (<ul 
                                                                   (<li (render-link 
                                                                          (lambda (&rest args)
                                                                            (regenerate-model-classes)
                                                                            (mark-dirty grid))
                                                                          "Regenerate db data from schema"))
                                                                   (<li (render-link 
                                                                          (lambda (&rest args)
                                                                            (save-schema)
                                                                            (setf *current-schema* (read-schema))

                                                                            (regenerate-model-classes)
                                                                            (mark-dirty grid))
                                                                          "Save schema to file"))
                                                                   (<li (render-link 
                                                                          (lambda (&rest args)
                                                                            (setf *current-schema* (read-schema))

                                                                            (regenerate-model-classes)
                                                                            (mark-dirty grid))
                                                                          "Load schema from file")))
                                                                 (<h3 "Model Classes:")))))
                                          (make-instance 'composite :widgets (list action-links grid))) nil)
                                  (list "Models Fields"
                                        (make-instance 
                                          'popover-gridedit 
                                          :data-class 'field-description 
                                          :view (defview nil (:type table :inherit-from '(:scaffold field-description))
                                                         (model :present-as text 
                                                                :reader (lambda (item)
                                                                          (format nil "~A (~A)" 
                                                                                  (model-description-title (field-description-model item))
                                                                                  (string-downcase (model-description-name (field-description-model item)))))))
                                          :item-form-view (field-form-view)) "fields")
                                  (list "Preview Models"
                                        (lambda (&rest args)
                                          (regenerate-model-classes)

                                          (loop for i in *current-schema* do 
                                                (render-widget 
                                                  (make-quickform (get-model-form-view (getf i :name) :display-buttons nil)))))
                                        "forms-preview")))))))
