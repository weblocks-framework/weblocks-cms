(in-package :weblocks-cms)

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

(defgeneric bootstrap-typeahead-title (obj)
  (:documentation "Method which should return unique string which can be used for object finding")
  (:method ((obj standard-object))
   (format nil "bootstrap-typeahead-title of ~A with id ~A" (type-of obj) (object-id obj))))

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
                                (loop for i in (explode (string #\Newline) (getf description :options)) 
                                      collect (cons i (attributize-name (string-trim (format nil " ~A" #\Return) i))))))
       :parse-as 'checkboxes)))
  (:method ((type (eql :single-choice)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as (list 'radio :choices 
                         (lambda (&rest args)
                           (loop for i in (explode (string #\Newline) (getf description :options)) 
                                 collect (cons i (attributize-name (string-trim (format nil " ~A" #\Return) i))))))
       :writer (lambda (value item)
                 (setf (slot-value item (keyword->symbol (getf description :name)))
                       (when value
                         (alexandria:make-keyword (string-upcase value))))))))
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
       :present-as 'tinymce-textarea)))
  (:method ((type (eql :single-relation)) description model-description-list)
   (let ((relation-model-description-list (get-model-description-from-field-description-options description)))
     (list 
       (cond 
         (relation-model-description-list 
           (list 
             (keyword->symbol (getf description :name))
             :label (getf description :title)
             :present-as (list 
                           'bootstrap-typeahead 
                           :display-create-message nil
                           :choices 
                           (if (description-of-a-tree-p relation-model-description-list)
                             (lambda (item)
                               (mapcar #'cdr (tree-item-text-tree (keyword->symbol (getf relation-model-description-list :name)) nil)))
                             (lambda (item)
                               (mapcar #'bootstrap-typeahead-title (all-of (keyword->symbol (getf relation-model-description-list :name)))))))
             :reader (if (description-of-a-tree-p relation-model-description-list)
                       (lambda (item)
                         (let ((item (slot-value item (keyword->symbol (getf description :name)))))
                           (and 
                             item
                             (tree-path-pretty-print item))))
                       (lambda (item)
                         (let ((item (slot-value item (keyword->symbol (getf description :name)))))
                           (and 
                             item
                             (bootstrap-typeahead-title item)))))
             :writer (if (description-of-a-tree-p relation-model-description-list)
                       (lambda (value item)
                         (setf 
                           (slot-value item (keyword->symbol (getf description :name)))
                           (parse-tree-item-from-text 
                             (keyword->symbol (getf relation-model-description-list :name))
                             value)))
                       (lambda (value item)
                         (setf 
                           (slot-value item (keyword->symbol (getf description :name)))
                           (first-by 
                             (keyword->symbol (getf relation-model-description-list :name))
                             (lambda (item) 
                               (string= (bootstrap-typeahead-title item) value))))))))
         (t 
          (list 
            (keyword->symbol (getf description :name))
            :hidep t
            :label (getf description :title))))))))
