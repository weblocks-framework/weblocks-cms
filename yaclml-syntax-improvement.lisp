(in-package :weblocks-cms)

#| 
Version: 0.0.3

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

#-YACLML-SYNTAX-IMPROVEMENT
(defvar *original-bracket-macro-reader* (get-macro-character #\())

#-YACLML-SYNTAX-IMPROVEMENT
(defmacro print-tag (tag &rest args)
  (setf tag (subseq (string tag) 1))
  (unless (find-symbol tag :<)
    (eval `(yaclml::def-simple-xtag ,(intern tag :<))))
  `(,(find-symbol tag :<) ,@args))

#-YACLML-SYNTAX-IMPROVEMENT
(defun debug-dispatch (stream char)
  (let* ((first-char (read-char stream))
         (second-char (peek-char nil stream nil))
         (function-starts-with-<-and-not-colon 
           (and 
             second-char
             (equal #\< first-char)
             (not (equal #\: second-char))
             (not (equal #\Space second-char))
             (not (equal #\= second-char))
             (not (equal #\) second-char)))))

    (unread-char first-char stream )

    (if function-starts-with-<-and-not-colon
      (funcall *original-bracket-macro-reader*  
               (make-concatenated-stream 
                 (make-string-input-stream "weblocks-cms::print-tag ")
                 stream)
               char)
      (funcall *original-bracket-macro-reader* stream char))))

#-YACLML-SYNTAX-IMPROVEMENT
(set-macro-character #\( #'debug-dispatch)

#-YACLML-SYNTAX-IMPROVEMENT
(push :yaclml-syntax-improvement *features*)
