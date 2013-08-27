(in-package :weblocks-cms)

(defmethod tree-item-title ((obj standard-object))
  "Used to display tree items in tree-edit and in other places"
  (format nil "Tree item of class ~A with id ~A" (type-of obj) (object-id obj)))

(defmethod tree-item-parent ((obj standard-object))
  (slot-value obj (keyword->symbol :parent)))

(defmethod tree-path ((obj standard-object))
  (append   
    (and 
      (tree-item-parent obj)
      (tree-path (tree-item-parent obj)))
    (list (tree-item-title obj))))

(defmethod tree-path-pretty-print ((obj standard-object))
  (join " > " (tree-path obj)))

(defun tree-item-text-tree (object-type &optional parent)
  (loop for i in (find-by-values object-type :parent parent) append 
        (append  
          (list (cons i (tree-path-pretty-print i)))
          (tree-item-text-tree object-type i))))

(defun string-downcase-trimmed-= (str1 str2)
  (string= 
    (string-downcase (string-trim " " str1))
    (string-downcase (string-trim " " str2))))

(defun parse-tree-item-from-text (object-type text)
  (let ((path-elems (ppcre:split "\\s+>\\s+" text))
        (tree-item))

    (loop for elem in path-elems do 

          (setf tree-item 
                (first-by  
                  object-type
                  (lambda (item)
                    (and 
                      (equal (tree-item-parent item) tree-item)
                      (string-downcase-trimmed-= (tree-item-title item) elem)))))

          (unless tree-item 
            (return-from parse-tree-item-from-text)))

    tree-item))
