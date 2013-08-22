Weblocks CMS - CMS built with weblocks.

The idea of weblocks-cms is to have an admin interface over normal admin interface.
First you edit application data schema - a set of models and their fields and include somewhere code which will create UI from this schema.

For schema editing we starting weblocks-cms application along with our admin application.
weblocks-cms will be available on /super-admin url.

Schema is usually saved in `getcwd`/schema.lisp-expr file.

During application loading last schema should be loaded and classes should be generated from it.
Classes (their symbols) should be in your application package, this is most convenient.

So, we set *models-package* - a package for model classes somewhere in the code

(defparameter weblocks-cms:*models-package* :package-name-for-models)

and regenerating classes from schema

(weblocks-cms:regenerate-model-classes)

this should be evaluated before opening stores and this is required init code.

By default you can edit schema (on /super-admin) without authentication, to restrict access to application you should override weblocks-cms:weblocks-cms-access-granted function with some authentication logic.

Here is example of embedding generated models into your admin interface

(do-page 
  (apply 
    #'make-navigation 
    (append 
      (list
        "toplevel"
        (list 
           "Custom page" 
           (lambda(&rest args) ...)
           nil))
       (weblocks-cms:models-gridedit-widgets-for-navigation)
       (list :navigation-class 'bootstrap-navbar-navigation))))

The result is separate tab for every generated model and gridedit on every tab.
