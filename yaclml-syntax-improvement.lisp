(in-package :weblocks-cms)

#| 
Version: 0.0.2

Example of using yaclml after this code evaluating

CL-USER> (<a :href "asdf" "jkl")
<a href="asdf"
  >jkl</a
>; No value
CL-USER> (<some-undefined-tag :some-parameter "asdf" "jkl")
<some-undefined-tag some-parameter="asdf"
  >jkl</some-undefined-tag
>; No value
CL-USER> 

|#

(defvar *original-bracket-macro-reader* (get-macro-character #\())

(defmacro print-tag (tag &rest args)
  (setf tag (subseq (string tag) 1))
  (unless (find-symbol tag :<)
    (eval `(yaclml::def-simple-xtag ,(intern tag :<))))
  `(,(find-symbol tag :<) ,@args))

(defun debug-dispatch (stream char)
  (let* ((first-char (read-char stream))
         (function-starts-with-<-and-not-colon 
           (and 
             (equal #\< first-char)
             (prog1 
               (not (equal #\: (peek-char nil stream)))))))

    (unread-char first-char stream )

    (if function-starts-with-<-and-not-colon
      (funcall *original-bracket-macro-reader*  
               (make-concatenated-stream 
                 (make-string-input-stream "print-tag ")
                 stream)
               char)
      (funcall *original-bracket-macro-reader* stream char))))

(set-macro-character #\( #'debug-dispatch)
