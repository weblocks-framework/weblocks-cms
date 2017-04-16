(in-package :weblocks-cms)

(defmacro with-yaclml (&body body)
  "A wrapper around cl-yaclml with-yaclml-stream macro."
  `(yaclml:with-yaclml-stream *weblocks-output-stream*
     ,@body))

(defwidget popover-gridedit(gridedit)
           ())

(defmethod render-widget-body ((obj popover-gridedit) &rest args &key
			       pre-data-mining-fn post-data-mining-fn)
  (declare (ignore args))
  (dataedit-update-operations obj)
    ;; Do necessary bookkeeping
  (dataseq-update-sort-column obj)
  (when (dataseq-allow-pagination-p obj)
    (setf (pagination-total-items (dataseq-pagination-widget obj))
	  (dataseq-data-count obj)))
  ;; Render Data mining
  (safe-funcall pre-data-mining-fn obj)
  (when (and (>= (dataseq-data-count obj) 1)
	     (or (dataseq-allow-select-p obj)
		 (dataseq-show-total-items-count-p obj)))
    (apply #'dataseq-render-mining-bar obj args))
  (safe-funcall post-data-mining-fn obj)
  ;; Render flash
  (render-widget (dataseq-flash obj))
  ;; Render Body
  (flet ((render-body ()
	   ;; Render items
	   (apply #'render-dataseq-body obj args)
	   ;; Render item ops
	   (when (and (dataseq-allow-operations-p obj)
		      (or (dataseq-item-ops obj)
			  (dataseq-common-ops obj)))
	     (apply #'dataseq-render-operations obj args))))
    (if (dataseq-wrap-body-in-form-p obj)
	(with-html-form (:get (make-action (alexandria:curry #'dataseq-operations-action obj))
			      :class "dataseq-form")
	  (render-body))
	(render-body)))
  ;; Render Pagination
  (when (dataseq-allow-pagination-p obj)
    (dataseq-render-pagination-widget obj)))

(defmethod dataedit-add-items-flow ((obj popover-gridedit) sel)
  "Initializes the flow for adding items to the dataedit."
  (declare (ignore sel))
  (cont:with-call/cc
    (setf (dataedit-item-widget obj)
          (dataedit-create-new-item-widget obj))
    (setf (dataedit-ui-state obj) :add)
    (do-widget obj (dataedit-item-widget obj))
    (setf (dataedit-item-widget obj) nil)
    (dataedit-reset-state obj)))

(defmethod dataedit-create-new-item-widget ((grid popover-gridedit))
  (make-instance 'dataform
                 :data (make-instance (dataseq-data-form-class grid))
                 :class-store (dataseq-class-store grid)
                 :ui-state :form
                 :on-cancel (lambda/cc (obj)
                              (declare (ignore obj))
                              (answer (dataedit-item-widget grid) nil))
                 :on-success (lambda/cc (obj)
                               (answer (dataedit-item-widget grid) t))
                 :data-view (dataedit-item-data-view grid)
                 :form-view (dataedit-item-form-view grid)))

(defmethod dataedit-create-drilldown-widget ((grid popover-gridedit) item)
  (make-instance 'dataform
                 :data item
                 :class-store (dataseq-class-store grid)
                 :ui-state :form
                 :on-success (lambda (obj)
                               (declare (ignore obj))
                               (flash-message (dataseq-flash grid)
                                              (format nil (translate "Modified ~A." :preceding-gender (determine-gender (humanize-name (dataseq-data-class grid))))
                                                      (translate (humanize-name (dataseq-data-class grid)))))
                               (answer (dataedit-item-widget grid) t))
                 :on-cancel (when (eql (gridedit-drilldown-type grid) :edit)
                              (lambda (obj)
                                (declare (ignore obj))
                                (answer (dataedit-item-widget grid) nil)))
                 :on-close (lambda (obj)
                             (declare (ignore obj))
                             (dataedit-reset-state grid))
                 :data-view (dataedit-item-data-view grid)
                 :form-view (dataedit-item-form-view grid)))

(defmethod dataedit-drilldown-action :around ((grid popover-gridedit) item)
  (cl-cont:with-call/cc 
    (call-next-method)
    (do-widget grid (dataedit-item-widget grid))
    (dataedit-reset-state grid)))

(defmethod widget-translation-table append ((obj (eql 'popover-gridedit)) &rest args)
  `((:edit-button-caption . ,(translate "Edit"))))

(defmethod widget-translation-table append ((obj popover-gridedit) &rest args)
  (widget-translation-table 'popover-gridedit))

(defun grid-with-edit-button-row-wt (&key row-class prefix suffix row-action session-string content alternp drilled-down-p move-up-action move-down-action display-up-action display-down-action &allow-other-keys )
  (yaclml:with-yaclml-output-to-string
    (<:as-is prefix)
    (<tr :class (format nil "~A~A" row-class (if drilled-down-p " info" ""))
         (<:as-is content))
    (<:as-is suffix)))

(defun grid-with-edit-button-context-p (&key widget &allow-other-keys)
  (if (typep widget 'popover-gridedit)
    50
    0))

(weblocks-util:deftemplate :datagrid-table-view-body-row-wt 'grid-with-edit-button-row-wt 
                           :application-class 'twitter-bootstrap-webapp 
                           :context-matches 'grid-with-edit-button-context-p)

(defun grid-with-edit-button-header-row-wt (&key suffix content prefix)
  (with-html-to-string
    (str suffix)
    (:tr (str content))
    (str prefix)))

(weblocks-util:deftemplate :table-header-row-wt 
                           'grid-with-edit-button-header-row-wt 
                           :application-class 'twitter-bootstrap-webapp 
                           :context-matches 'grid-with-edit-button-context-p)

(defun grid-with-edit-button-header-row-wt (&key suffix content prefix)
  (with-html-to-string
    (str suffix)
    (:tr (str content))
    (str prefix)))

(weblocks-util:deftemplate :table-header-row-wt 
                           'grid-with-edit-button-header-row-wt 
                           :application-class 'twitter-bootstrap-webapp 
                           :context-matches 'grid-with-edit-button-context-p)

(defun grid-with-edit-button-buttons-cell-wt (&key content)
  (yaclml:with-yaclml-output-to-string
    (<td (<:as-is content))))

(weblocks-util:deftemplate :table-buttons-cell-wt 
                           'grid-with-edit-button-buttons-cell-wt 
                           :application-class 'twitter-bootstrap-webapp 
                           :context-matches 'grid-with-edit-button-context-p)


(defmethod render-view-field ((field datagrid-drilldown-field) (view table-view)
                                                               (widget popover-gridedit) presentation value obj &rest args
                                                               &key row-action &allow-other-keys)
  (declare (ignore args))

  (weblocks-util:render-wt 
    :table-buttons-cell-wt
    (list :view view :field field :widget widget :presentation presentation :value value :object obj)
    :content (yaclml:with-yaclml-output-to-string 
               (<div :class "btn-group"
                     (<a :class "btn btn-small btn-info" :href "javascript:;" :onclick (format nil "initiateAction(\"~A\", \"~A\");" row-action (session-name-string-pair))
                         (<i :class "icon-pencil")
                         (<:as-is "&nbsp;") 
                         (<:as-is (widget-translate 'popover-gridedit :edit-button-caption)))))))

(defmethod render-view-field-header ((field datagrid-drilldown-field) (view table-view)
                                     (widget popover-gridedit) presentation value obj &rest args)
  (declare (ignore args))
  (with-html (:th 
                  "")))

