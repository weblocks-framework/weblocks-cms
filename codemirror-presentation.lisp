(in-package :weblocks-cms)

(defclass codemirror-presentation (textarea-presentation)
  ()
  (:documentation "A presentation to turn textarea into code editor"))

(defparameter *codemirror-css* 
  '(ps:create "border" "1px solid #cccccc" 
              "border-radius" "4px"))

(defmethod render-view-field-value :around (value (presentation codemirror-presentation) 
                                                  (field form-view-field) (view form-view) widget obj
                                                  &rest args)
  (declare (special weblocks:*presentation-dom-id*))

  (weblocks-utils:require-assets "https://raw.github.com/html/weblocks-assets/master/codemirror/3.20/")
  (weblocks-utils:require-assets "https://raw.github.com/html/weblocks-assets/master/codemirror-mustache-addon/rev-2/")

  (with-javascript
    (ps:ps*
      `(with-scripts 
         (ps:LISP  (weblocks-utils:prepend-webapp-path "/pub/scripts/codemirror/lib/codemirror.js"))
         (ps:LISP (weblocks-utils:prepend-webapp-path "/pub/scripts/codemirror/mode/xml/xml.js") )
         (ps:LISP (weblocks-utils:prepend-webapp-path "/pub/scripts/codemirror/addon/mode/overlay.js") )
         (ps:LISP (weblocks-utils:prepend-webapp-path "/pub/scripts/codemirror-mustache.js") )
         (lambda ()
           (with-styles
             (ps:LISP  (weblocks-utils:prepend-webapp-path "/pub/scripts/codemirror/lib/codemirror.css"))
             (ps:LISP  (weblocks-utils:prepend-webapp-path "/pub/stylesheets/mustache-mode.css"))
             (lambda ()
               (ps:chain 
                 (j-query (ps:LISP (format nil "#~A" weblocks:*presentation-dom-id*)))
                 (on-available
                   (lambda ()
                     (let ((editor (*code-mirror.from-text-area 
                                     (document.get-element-by-id (ps:LISP weblocks:*presentation-dom-id*))
                                     (ps:create 
                                       :mode "mustache"
                                       "lineWrapping" t))))

                       (ps:chain (j-query (ps:@ editor display wrapper))
                                 (css (ps:LISP *codemirror-css*)))

                       (ps:chain 
                         editor 
                         (on "change"
                             (lambda (cm)
                               (setf (slot-value 
                                       (document.get-element-by-id (ps:LISP weblocks:*presentation-dom-id*))
                                       'value) (ps:chain cm (get-value))))))))))))))))
  (call-next-method))
