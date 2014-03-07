(in-package :weblocks-cms)

(defclass form-with-sticky-buttons-view (form-view)
  ())

(defclass form-with-sticky-buttons-view-field (form-view-field)
  ())

(defclass form-with-sticky-buttons-scaffold (form-scaffold)
  ())

(defun make-form-buttons-sticky-js (&rest args)
  (with-html 
    (:script :type "text/javascript"
     (str 
       (ps:ps 
         (j-query 
           (lambda () 
             (let* ((div (j-query "div.submit"))
                    (height (ps:chain (j-query "div.submit") (outer-height)))
                    (wrapper (ps:chain 
                               div 
                               (wrap "<div class='scroll-wrapper'></div>")
                               (parent)
                               (height height)))
                    (start-offset 10))

               (ps:chain (j-query window) 
                         (scroll 
                           (lambda ()
                             (let* ((original-offset (ps:chain wrapper (offset)))
                                    (el-bottom-point-from-top (+ (ps:@ original-offset top) height))
                                    (win-bottom-point-from-top (+ (ps:chain (j-query window) (scroll-top)) 
                                                                  (ps:chain (j-query window) (height)))))
                               (if (<= 
                                     (- win-bottom-point-from-top start-offset)
                                     el-bottom-point-from-top)
                                 (ps:chain (j-query "div.submit") (add-class "fixed"))
                                 (progn 
                                   (ps:chain (j-query "div.submit") (remove-class "fixed"))
                                   ; XXX, this for bug fixing
                                   (setf original-offset (ps:chain (j-query "div.submit") (offset))))))))
                         (trigger "scroll"))))))))))

(defmethod render-form-view-buttons :before ((view form-with-sticky-buttons-view) obj widget &rest args)
  (make-form-buttons-sticky-js))
