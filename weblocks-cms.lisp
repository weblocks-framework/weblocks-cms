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
                     :inherit-from ',(list :scaffold (keyword->symbol (getf description :name))))
                ,@(loop for j in (getf description :fields) 
                        append (get-table-view-fields-for-field-description j description))))))

(defun regenerate-model-classes (&optional (schema *current-schema*))
  (loop for i in schema do
        (eval
          `(defclass ,(keyword->symbol (getf i :name)) ()
             ((,(keyword->symbol :id))
              ,@(loop for j in (getf i :fields) collect 
                      (append 
                        (list 
                          (keyword->symbol (getf j :name))

                          :initarg (getf j :name)
                          :initform nil
                          :accessor (intern (string-upcase (format nil "~A-~A" (getf i :name)  (getf j :name))) *models-package*))
                        (cond 
                          ((find (getf i :type) (list :string :integer))
                           (list :type (getf j :type)))
                          (t nil)))))))))

(defun refresh-schema()
  (setf *current-schema* (read-schema))
  (regenerate-model-classes))

(defun get-view-fields-for-field-description (i model-description-list)
  (get-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun get-table-view-fields-for-field-description (i model-description-list)
  (get-table-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun make-gridedit-for-model-description (i)
  (make-instance 
    'gridedit 
    :data-class (keyword->symbol (getf i :name))
    :item-form-view (get-model-form-view (getf i :name))
    :view (get-model-table-view (getf i :name))))

(defun make-tree-edit-for-model-description (i)
  (let* ((model-class (keyword->symbol (getf i :name)))
         (grid)
         (view (get-model-form-view (getf i :name))))
    (setf grid (make-instance 'tree-edit 
                              :item-form-view (get-model-form-view (getf i :name))
                              :view (defview nil (:type tree)
                                             (data 
                                               :label "Tree"
                                               :present-as tree-branches 
                                               :reader (lambda (item)
                                                         (if (typep item model-class)
                                                           (tree-item-title item)
                                                           (tree-item-title (getf item :item)))))
                                             (action-links 
                                               :label "Actions"
                                               :present-as html 
                                               :reader (lambda (item)
                                                         (funcall (action-links-reader grid view) item))))
                              :data-class model-class))
    grid))

(defun description-of-a-tree-p (model-description)
  (loop for i in (getf model-description :fields) do 
        (when (and 
                (equal (getf i :name) :parent)
                (equal (getf i :type) :single-relation))
          (return-from description-of-a-tree-p t))))

(defun models-gridedit-widgets-for-navigation ()
  (loop for i in *current-schema* collect 
        (list 
          (getf i :title)
          (funcall 
            (if (description-of-a-tree-p i)
              #'make-tree-edit-for-model-description
              #'make-gridedit-for-model-description) i)
          (string-downcase (getf i :name)))))
