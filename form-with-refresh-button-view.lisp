(in-package :weblocks-cms)

(defclass form-with-refresh-button-view (form-with-sticky-buttons-view)
  ())

(defclass form-with-refresh-button-view-field (form-view-field)
  ())

(defclass form-with-refresh-button-scaffold (form-scaffold)
  ())

(defmethod render-form-view-buttons ((view form-with-refresh-button-view) obj widget &rest args &key buttons &allow-other-keys)
  (declare (ignore obj args))
  (setf form-view-buttons (form-view-buttons view))
  (flet ((find-button (name)
           (weblocks::ensure-list
             (if form-view-buttons
               (find name form-view-buttons
                     :key (lambda (item)
                            (car (weblocks::ensure-list item))))
               (find name (form-view-buttons view)
                     :key (lambda (item)
                            (car (weblocks::ensure-list item))))))))
    (let ((submit (find-button :submit))
          (cancel (find-button :cancel))
          (other-buttons (loop for i in form-view-buttons 
                               unless (find (car (weblocks::ensure-list i)) (list :submit :cancel))
                               collect (weblocks::ensure-list i))))
      (write-string 
        (weblocks::render-wt-to-string 
          :form-view-buttons-wt
          (list :view view :object obj :widget widget)
          :submit-html (let ((submit submit))
                         (weblocks::capture-weblocks-output
                           (when submit
                             (render-button *submit-control-name*
                                            :value (widget-dynamic-translate 
                                                     view 
                                                     :submit-button-title
                                                     (translate (or (cdr submit)
                                                                    (humanize-name (car submit)))))))
                           (loop for (name . title) in other-buttons 
                                 do 
                                 (with-yaclml 
                                   (<:as-is "&nbsp;")
                                   (<input 
                                     :onclick (ps:ps 
                                                (initiate-form-action 
                                                  (ps:LISP 
                                                    (function-or-action->action 
                                                      (lambda (&rest args)
                                                        (multiple-value-bind (success errors)
                                                          (apply #'update-object-view-from-request 
                                                                 (dataform-data widget) view 
                                                                 :class-store (dataform-class-store widget)
                                                                 args)
                                                          (mark-dirty widget :propagate t)
                                                          (if success 
                                                            (progn 
                                                              (setf (slot-value widget 'weblocks::validation-errors) errors)
                                                              (send-script 
                                                                (ps:ps (alert "Saved successfully"))))
                                                            (progn 
                                                              (setf (slot-value widget 'weblocks::validation-errors) errors)
                                                              (setf (slot-value widget 'weblocks::intermediate-form-values)
                                                                    (apply #'request-parameters-for-object-view
                                                                           view (dataform-data widget) args))))))))
                                                  (ps:chain (j-query this) (parents "form"))
                                                  (ps:LISP (session-name-string-pair))))
                                     :type "button" :name name :value title :class "submit btn btn-primary")))))
          :cancel-html (let ((cancel cancel))
                         (when cancel
                           (weblocks::capture-weblocks-output 
                             (render-button *cancel-control-name*
                                            :class "submit cancel"
                                            :value (widget-dynamic-translate 
                                                     view 
                                                     :cancel-button-title
                                                     (translate (or (cdr cancel)
                                                                    (humanize-name (car cancel))))))))))
        *weblocks-output-stream*))))
