(in-package :weblocks-cms)


(defclass field-description ()
  ((id)
   (title :initarg :title :accessor field-description-title)
   (name :initarg :name :accessor field-description-name :type keyword)
   (type :initarg :type :accessor field-description-type :type keyword)
   (type-data :initarg :type-data :accessor field-description-type-data)
   (model :initarg :model :accessor field-description-model)))

(defmethod dump-field-description ((field field-description))
  (list 
    :title (field-description-title field)
    :name (field-description-name field)
    :type (field-description-type field)
    :options (field-description-type-data field)))
