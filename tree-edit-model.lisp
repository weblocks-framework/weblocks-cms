(in-package :weblocks-cms)

(defmethod tree-item-title ((obj standard-object))
  (format nil "Tree item of class ~A with id ~A" (type-of obj) (object-id obj)))

#+l(defmethod tree-item-parent ((obj standard-object))
  (slot-value obj 'parent))

#+l(defmethod tree-path ((obj standard-object))
  (append   
    (and 
      (tree-item-parent obj)
      (tree-path (tree-item-parent obj)))
    (list (tree-item-title obj))))

#+l(defmethod tree-path-pretty-print ((obj standard-object))
  (join " > " (tree-path obj)))

#+l(defun tree-item-text-tree (obj)
  (loop for i in (find-by-values 'catalog-item :parent obj) append 
        (append  
          (list (cons i (tree-path-pretty-print i)))
          (tree-item-text-tree i))))

