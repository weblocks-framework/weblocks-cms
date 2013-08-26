(in-package :weblocks-cms)

(defparameter *tinymce-settings* 
  "({
        mode : \"exact\",
        elements : '~A',
        plugins: [
        \"advlist autolink lists link image charmap print preview anchor\",
        \"searchreplace visualblocks code fullscreen\",
        \"insertdatetime media table contextmenu paste\"
        ],
        toolbar: \"insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image\"
})")

(defclass tinymce-textarea-presentation (textarea-presentation)
  ())

(defmethod render-view-field-value :around (value (presentation tinymce-textarea-presentation) 
                                                  (field form-view-field) (view form-view) widget obj
                                                  &rest args)
  (declare (special weblocks:*presentation-dom-id*))
  (weblocks-utils:require-assets "https://raw.github.com/html/weblocks-assets/master/tinymce/4.0.4/")
  (with-javascript
    (ps:ps*
      `(with-scripts 
         (ps:LISP (weblocks-utils:prepend-webapp-path "/tinymce/tinymce.js"))
         (lambda ()
           (setf tinymce.base-u-r-l (ps:LISP (weblocks-utils:prepend-webapp-path "/tinymce/")))
           (setf window.tinymce.dom.-event.dom-loaded t)
           (tinymce.init 
             (eval ,(remove #\Newline (format nil *tinymce-settings* weblocks:*presentation-dom-id*))))))))
  (call-next-method))
