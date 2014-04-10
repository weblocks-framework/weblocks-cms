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

(defvar *additional-schemes* nil 
  "Additional schemes are not writen to schema file and used by Weblocks CMS plugins")

(defun get-model-form-view (model &key (display-buttons t))
  (let ((description (get-model-description model)))
    (eval 
      `(defview nil (:type form-with-refresh-button 
                           :caption ,(getf description :title)
                           :inherit-from ',(list :scaffold (keyword->symbol (getf description :name)))
                           :enctype "multipart/form-data"
                           :use-ajax-p t
                           ,@(if display-buttons 
                               (list :buttons (quote '((:submit . "Save & Close") (:update . "Save & Edit") (:cancel . "Close Without Saving"))))
                               (list :buttons nil)))
                ,@(loop for j in (getf description :fields) 
                        append (get-view-fields-for-field-description j description))))))

(defun get-model-table-view (model)
  (let ((description (get-model-description model)))
    (eval 
      `(defview nil (:type table 
                     :inherit-from ',(list :scaffold (keyword->symbol (getf description :name))))
                ,@(loop for j in (getf description :fields) 
                        append (get-table-view-fields-for-field-description j description))))))

(defun maybe-create-class-db-data (description)
  "Creates records for class and its fields information if it does not exist"
  (if weblocks-stores:*default-store*
    (let ((model-descr 
            (or (first-by-values 'model-description :name (getf description :name))
                (persist-object weblocks-stores:*default-store* 
                                (make-instance 'model-description :name (getf description :name) :title (getf description :title))))))
      (loop for i in (getf description :fields)
            do (or (first-by-values 'field-description 
                                    :model model-descr 
                                    :name (getf i :name))
                   (persist-object 
                     weblocks-stores:*default-store* 
                     (make-instance 'field-description 
                                    :name (getf i :name)
                                    :title (getf i :title)
                                    :type (getf i :type)
                                    :type-data (getf i :type-data)
                                    :model model-descr)))))
    (warn "Description db data not generated for class ~A, store is not yet opened" (getf description :name))))

(defun generate-model-class-from-description (i)
  "Creates CLOS class by schema class description list"
  (eval
    `(defclass ,(keyword->symbol (getf i :name)) ()
       ((,(keyword->symbol :id))
        ,@(loop for j in (getf i :fields) collect 
                (append 
                  (list 
                    (keyword->symbol (getf j :name))

                    :initarg (alexandria:make-keyword (string-upcase (getf j :name)))
                    :initform nil
                    :accessor (intern (string-upcase (format nil "~A-~A" (getf i :name)  (getf j :name))) *models-package*))
                  (cond 
                    ((find (getf i :type) (list :string :integer))
                     (list :type (getf j :type)))
                    (t nil))))))))

(defun available-schemes-data (&optional (schema *current-schema*))
  (apply #'append (list* schema (mapcar #'cdr *additional-schemes*))))

(defun regenerate-model-classes (&optional (schema *current-schema*))
  "Transforms schema description to classes"
  (loop for i in (available-schemes-data schema) do
        (generate-model-class-from-description i)
        (maybe-create-class-db-data i)))

(defun refresh-schema()
  (setf *current-schema* (read-schema))
  (regenerate-model-classes))

(defun get-view-fields-for-field-description (i model-description-list)
  (get-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun get-table-view-fields-for-field-description (i model-description-list)
  (get-table-view-fields-for-field-type-and-description (getf i :type) i model-description-list))

(defun make-gridedit-for-model-description (i)
  (make-instance 
    'popover-gridedit 
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
  (loop for i in (available-schemes-data) collect 
        (list 
          (getf i :title)
          (funcall 
            (if (description-of-a-tree-p i)
              #'make-tree-edit-for-model-description
              #'make-gridedit-for-model-description) i)
          (string-downcase (getf i :name)))))

(defvar *admin-menu-widgets* nil 
  "Contains list of menu items, each menu item is either a list of title/widget/name for navigation or a callback which should return title/widget/name")

(defun weblocks-cms-admin-menu ()
  (append 
    (models-gridedit-widgets-for-navigation)
    (loop for i in *admin-menu-widgets* 
          collect (if (functionp i)
                    (funcall i)
                    i))))

(defun def-additional-schema (name schema)
                       (push (cons name schema) *additional-schemes*)
                       (mapcar #'generate-model-class-from-description schema))
