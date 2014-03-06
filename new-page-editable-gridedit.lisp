(in-package :weblocks-cms)

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

