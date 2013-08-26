;;;; weblocks-cms.lisp

(in-package #:weblocks-cms)

;;; Hacks and glory await!

(defwebapp weblocks-cms
           :prefix "/super-admin"
           :description "Weblocks CMS"
           :init-user-session 'init-super-admin-session
           :subclasses (weblocks-twitter-bootstrap-application:twitter-bootstrap-webapp)
           :autostart nil                   ;; have to start the app manually
           :ignore-default-dependencies nil ;; accept the defaults
           :debug t)

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
                                                    ("File" . file)))
                      :reader (lambda (item)
                                (string-downcase (slot-value item 'type))) 
                      :writer (lambda (value item)
                                (setf (slot-value item 'type) (alexandria:make-keyword (string-upcase value)))))
                (type-data :present-as textarea)
                ,(related-record-field 'model-description #'model-description-title (list :requiredp t) :field-name 'model)))

(defun get-model-form-view (model &key (display-buttons t))
  (let ((description (get-model-description model)))
    (eval 
      `(defview nil (:type form 
                     :caption ,(getf description :title)
                     :inherit-from ',(list :scaffold (keyword->symbol (getf description :name)))
                     ,@(unless display-buttons (list :buttons nil)))
                ,@(loop for j in (getf description :fields) 
                        append (get-view-fields-for-field-description j description))))))

(defun get-model-table-view (model)
  (let ((description (get-model-description model)))
    (eval 
      `(defview nil (:type table 
                     :caption ,(getf description :title)
                     :inherit-from ',(list :scaffold (keyword->symbol (getf description :name))))
                ,@(loop for j in (getf description :fields) 
                        append (get-table-view-fields-for-field-description j description))))))

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

(defun regenerate-model-classes (&optional (schema *current-schema*))
  (loop for i in schema do
        (eval
          `(defclass ,(keyword->symbol (getf i :name)) ()
             ((,(keyword->symbol :id))
              ,@(loop for j in (getf i :fields) collect 
                      (append 
                        (list 
                          (keyword->symbol (getf j :name))

                          :initform nil
                          :accessor (intern (string-upcase (format nil "~A-~A" (getf i :name)  (getf j :name))) *models-package*))
                        (cond 
                          ((find (getf i :type) (list :string :integer))
                           (list :type (getf j :type)))
                          (t nil)))))))))

(defparameter *upload-directory* 
  (merge-pathnames 
    (make-pathname :directory '(:relative "pub" "upload"))
    (uiop:getcwd)))

(defun get-field-upload-directory (model-description-list field-description)
  (merge-pathnames 
    (make-pathname 
      :directory (list :relative 
                       (format nil "~A-~A" 
                               (string-downcase (getf model-description-list :name))
                               (string-downcase (getf field-description :name)))))
    *upload-directory*))


(defun get-view-fields-for-field-description (i model-description-list)
  (get-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun get-table-view-fields-for-field-description (i model-description-list)
  (get-table-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun models-gridedit-widgets-for-navigation ()
  (loop for i in (dump-schema) collect 
        (list 
          (getf i :title)
          (make-instance 
            'gridedit 
            :data-class (keyword->symbol (getf i :name))
            :item-form-view (get-model-form-view (getf i :name))
            :view (get-model-table-view (getf i :name)))
          (string-downcase (getf i :name)))))
