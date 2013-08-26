(in-package :weblocks-cms)

(defclass model-description ()
  ((id)
   (title :accessor model-description-title)
   (name :accessor model-description-name :type keyword)))

(defmethod dump-model-description ((model model-description))
  (list :title (model-description-title model)
        :name (model-description-name model)
        :fields 
        (loop for i in (find-by-values 'field-description :model model)
              collect (dump-field-description i))))

(defvar *schema-file* (merge-pathnames 
                        (make-pathname :name "schema" :type "lisp-expr")
                        (uiop:getcwd)))

(defun dump-schema ()
  (mapcar #'dump-model-description (all-of 'model-description)))

(defun save-schema (&optional (file *schema-file*))
  (with-open-file 
    (out file 
         :direction :output 
         :if-does-not-exist :create 
         :if-exists :supersede)
    (pprint (dump-schema) out)))

(defun read-schema (&optional (file *schema-file*))
  (when (cl-fad:file-exists-p file)
    (with-open-file (in file :direction :input)
      (read in))))

(defvar *current-schema* (read-schema))

(defun get-model-description (model)
  (loop for i in *current-schema* do 
        (when (equal model (getf i :name))
          (return-from get-model-description i))))
