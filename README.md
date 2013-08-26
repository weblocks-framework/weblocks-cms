# Weblocks CMS - CMS built with weblocks.

## The Idea 

The idea of weblocks-cms is to have an admin interface on the top of normal admin interface.
First you edit application data schema - a set of models and their fields and include somewhere code which will create UI from this schema.

## Starting Weblocks CMS

For schema editing we starting weblocks-cms application along with our admin application.
weblocks-cms will be available on /super-admin url.

_We edit schema in web-interface_
_Schema is usually saved in `\`getcwd\`/schema.lisp-expr` file after clicking "Preview Models" button_
Current schema is the one from which admin interface is generated.
It is in `weblocks-cms:*current-schema*` variable and is updated when `(weblocks-cms:refresh-schema)` evaluated 
and during application loading.

First Weblocks CMS start (without schema) does not require initialization but when schema contains models 
and data related to these models you'll need initialization.

## Weblocks CMS Initialization

During application loading last schema should be loaded from schema file and classes should be generated from it.
Classes (their symbols) should be in your application package, this is most convenient.

So, we set `*models-package*` - a package for model classes somewhere in the code

```lisp
(defparameter weblocks-cms:*models-package* :package-name-for-models)
```

and regenerating classes from schema

```lisp
(weblocks-cms:regenerate-model-classes)
```

this should be evaluated before opening stores and this is required init code when you have schema and its data.

## Admin Panel Access

By default you can edit schema (on /super-admin) without authentication, to restrict access to application you should override weblocks-cms:weblocks-cms-access-granted function with some authentication logic.

## Turning Models Into Edit Interface

### Gridedit

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
You can also use `(weblocks-cms:make-gridedit-for-model-description < model description >)` to put grid where you want.

### Tree Edit

To make tree instead of grid you should add to your model column with name `parent` and type "Single Relation".
In this case `(weblocks-cms:models-gridedit-widgets-for-navigation)` will create tree from such description instead of grid.

You can also use `(weblocks-cms:make-tree-edit-for-model-description < model description >)` to put tree where you want.

You should also override `weblocks-cms:tree-item-title` method for your models, default title gives only debug information.
