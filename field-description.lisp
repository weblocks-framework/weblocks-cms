(in-package :weblocks-cms)


(defun dump-field-description (field)
  (list 
    :title (field-description-title field)
    :name (field-description-name field)
    :type (field-description-type field)
    :options (field-description-type-data field)))
