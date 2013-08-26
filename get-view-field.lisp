(in-package :weblocks-cms)

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
                 (setf (slot-value item (keyword->symbol (getf description :name))) (alexandria:make-keyword (string-upcase value)))))))
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
