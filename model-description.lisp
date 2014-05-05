(in-package :weblocks-cms)

(defclass model-description ()
  ((id)
   (title :initarg :title :accessor model-description-title)
   (name  :initarg :name :accessor model-description-name :type keyword)))

(defun string<-by-chars (str1 str2)
  (cond 
    ((or 
       (zerop (length str1))
       (zerop (length str2)))
     (> (length str1) (length str2)))
    ((char= (char str1 0) (char str2 0))
     (string<-by-chars (subseq str1 1) (subseq str2 1)))
    ((char< (char str1 0) (char str2 0)) t)))

(assert (equal '("Test" "Test") (sort (list "Test" "Test") #'string<-by-chars)))
(assert (equal '("2" "") (sort (list "" "2" ) #'string<-by-chars)))
(assert (equal '("Test2" "Test") (sort (list "Test" "Test2" ) #'string<-by-chars)))

(defmethod dump-model-description ((model model-description))
  (list :title (model-description-title model)
        :name (model-description-name model)
        :fields 
        (loop for i in (sort 
                         (find-by-values 'field-description :model model)
                         #'string<-by-chars
                         :key #'field-description-title)
              collect (dump-field-description i))))

(defvar *schema-file* (merge-pathnames 
                        (make-pathname :name "schema" :type "lisp-expr")
                        (uiop:getcwd)))

(defun dump-schema ()
  (let ((disabled-names (loop for i in (apply #'append (mapcar #'cdr weblocks-cms::*additional-schemes*))
                              collect (getf i :name))))
    (mapcar #'dump-model-description 
            (remove-if 
              (lambda (item)
                (find (model-description-name item) disabled-names))
              (sort 
                (all-of 'model-description)
                #'string<-by-chars 
                :key #'model-description-title)))))

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
  (loop for i in (available-schemes-data) do 
        (when (equal model (getf i :name))
          (return-from get-model-description i))))

(defun get-model-description-from-field-description-options (description)
  (get-model-description 
    (alexandria:make-keyword 
      (string-upcase 
        (string-trim (format nil " ~A~A" #\Newline #\Return)
                     (getf description :options))))))
