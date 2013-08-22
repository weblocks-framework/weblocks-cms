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

(defvar *models-package*)

(eval `(defview field-form-view (:type form :inherit-from '(:scaffold field-description))
                (title :requiredp t)
                (name :requiredp t 
                      :reader (lambda (item)
                                (string-downcase (slot-value item 'name)))
                      :writer (lambda (value item)
                                (setf (slot-value item 'name) (alexandria:make-keyword (string-upcase value)))))
                (type :present-as (radio :choices '(("Выбор да/нет" . boolean)
                                                    ("Целое число" . integer) 
                                                    ("Строка" . string)
                                                    ("Несколько строк текста" . textarea)
                                                    ("Редактор текста" . editor-textarea)
                                                    ("Дата и время" . datetime)
                                                    ("Единичный выбор" . single-choice)
                                                    ("Множественный выбор" . multiple-choices)
                                                    ("Файл" . file)))
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

(defun weblocks-cms-access-granted ()
  "Override this function for using login logic"
  t)

(defun/cc init-super-admin-session (root)
  (when (weblocks-cms-access-granted)
    (do-page 
      (make-navigation 
        "toplevel"
        (list "Модели" 
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
        (list "Поля моделей"
              (make-instance 
                'gridedit 
                :data-class 'field-description 
                :item-form-view 'field-form-view) "fields")
        (list "Предпросмотр форм моделей"
              (lambda (&rest args)
                (save-schema)
                (setf *current-schema* (read-schema))

                (regenerate-model-classes)
                (loop for i in *current-schema* do 
                      (render-widget 
                        (make-quickform (get-model-form-view (getf i :name) :display-buttons nil)))))
              "forms-preview")
        :navigation-class 'bootstrap-navbar-navigation))))

(defun reverse-cons (cons)
  (cons (cdr cons) (car cons)))

(defun keyword->symbol (keyword)
  (intern (string-upcase keyword) *models-package*))

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

(defun safe-parse-integer (number)
  (if (not number)
    0
    (parse-integer number :junk-allowed t)))

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

(defgeneric get-view-fields-for-field-type-and-description (type description model-description-list)
  (:documentation "Get view fields for specific field")
  (:method ((type (eql :integer)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'input 
       :writer (lambda (value item)
                 (setf (slot-value item (keyword->symbol (getf description :name)))
                       (safe-parse-integer value)))
       :reader (lambda (item)
                 (slot-value item (keyword->symbol (getf description :name)))))))
  (:method ((type (eql :string)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'input)))
  (:method ((type (eql :boolean)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'checkbox)))
  (:method ((type (eql :datetime)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'bootstrap-date-entry
       :parse-as 'bootstrap-date)))
  (:method ((type (eql :multiple-choices)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as (list 
                     'checkboxes 
                     :choices (lambda (&rest args)
                                (mapcar #'string-upcase (explode (string #\Newline) (getf description :options)))))
       :parse-as 'checkboxes)))
  (:method ((type (eql :single-choice)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as (list 'radio :choices 
                         (lambda (&rest args)
                           (mapcar #'string-upcase (explode (string #\Newline) (getf description :options))))))))
  (:method ((type (eql :textarea)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'textarea)))
  (:method ((type (eql :file)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'ajax-file-upload
       :parse-as (list 'ajax-file-upload 
                       :upload-directory (get-field-upload-directory model-description-list description))
       :writer (lambda (value item)
                 (when value 
                   (setf (slot-value item (keyword->symbol (getf description :name))) value))))))
  (:method ((type (eql :editor-textarea)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'tinymce-textarea))))

(defun get-view-fields-for-field-description (i model-description-list)
  (get-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun models-gridedit-widgets-for-navigation ()
  (loop for i in (dump-schema) collect 
        (list 
          (getf i :title)
          (make-instance 
            'gridedit 
            :data-class (keyword->symbol (getf i :name))
            :item-form-view (get-model-form-view (getf i :name)))
          (string-downcase (getf i :name)))))
