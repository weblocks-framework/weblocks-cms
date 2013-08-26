(in-package :weblocks-cms)

(defgeneric get-table-view-fields-for-field-type-and-description (type description model-description-list)
  (:documentation "Get view fields for specific field")
  (:method ((type (eql :integer)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title))))
  (:method ((type (eql :string)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title))))
  (:method ((type (eql :boolean)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :present-as 'predicate
       :label (getf description :title))))
  (:method ((type (eql :datetime)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'date)))
  (:method ((type (eql :multiple-choices)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'html
       :allow-sorting-p t
       :reader (lambda (item)
                 (let ((options 
                         (loop for i in (explode (string #\Newline) (getf description :options)) 
                               append 
                               (list 
                                 (alexandria:make-keyword (string-upcase (attributize-name (string-trim (format nil " ~A" #\Return) i))))
                                 (string-trim (format nil " ~A" #\Return) i)))))
                   (with-html-to-string 
                     (loop for i in (slot-value item (keyword->symbol (getf description :name))) 
                           collect (cl-who:htm 
                                     (:span :class "label label-info"
                                      (cl-who:str (getf options i)))
                                     (cl-who:str "&nbsp;")))))))))
  (:method ((type (eql :single-choice)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title))))
  (:method ((type (eql :textarea)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :allow-sorting-p t
       :present-as 'excerpt
       :label (getf description :title))))
  (:method ((type (eql :file)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title))))
  (:method ((type (eql :editor-textarea)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :label (getf description :title)
       :present-as 'excerpt
       :allow-sorting-p t
       :reader (lambda (item)
                 (strip-tags (slot-value item (keyword->symbol (getf description :name))))))))
  (:method ((type (eql :single-relation)) description model-description-list)
   (list 
     (list 
       (keyword->symbol (getf description :name))
       :hidep t
       :label (getf description :title)))))
