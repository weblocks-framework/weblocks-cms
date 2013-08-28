# Weblocks CMS - CMS built with Weblocks.

## The Idea 

The idea of *Weblocks CMS* is to have an admin interface on the top of normal admin interface.
First you edit application data schema - a set of models and their fields and include somewhere code which will create UI from this schema.

## Requirements

Weblocks CMS requires https://github.com/html/weblocks-twitter-bootstrap-application
It should work only with `weblocks-prevalence` store.
Package uses weblocks assets so all dependencies should be installed automatically.

## Starting Weblocks CMS

For schema editing we starting weblocks-cms application along with our admin application.
weblocks-cms will be available on /super-admin url.

_We edit schema in web-interface._
_Schema is usually saved in `< getcwd >/schema.lisp-expr` file after clicking "Preview Models" button_
Current schema is the one from which admin interface is generated.
It is in `weblocks-cms:*current-schema*` variable and is updated when `(weblocks-cms:refresh-schema)` evaluated 
and during application loading.

First *Weblocks CMS* start (without schema) does not require initialization but when schema contains models 
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

Here is example of embedding generated models into your admin interface

```lisp
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
```

The result is separate tab for every generated model and gridedit on every tab.

### Gridedit

You can also use `(weblocks-cms:make-gridedit-for-model-description < model description >)` to put grid where you want.

### Tree Edit

To make tree instead of grid you should add to your model column with name `parent` and type "Single Relation".
In this case `(weblocks-cms:models-gridedit-widgets-for-navigation)` will create tree from such description instead of grid.

You can also use `(weblocks-cms:make-tree-edit-for-model-description < model description >)` to put tree where you want.

You should also override `weblocks-cms:tree-item-title` method for your models, default title gives only debug information.

### Field Types

Choice yes/no     - turns into boolean value `T` or `NIL`, displays in grid as "Yes" or "No"

Integer           - turns into integer number

String            - turns into string

Few lines of text - textarea, turns into string, displays in grid as excerpt

Text editor       - tinymce editor, turns into string, displays in grid as excerpt from text with stripped html tags

Date and time     - date and time using Twitter Bootstrap widgets, turns into universal time (integer), displays in grid as date

Single choice     - single choice from list, turns into keyword. List of values should be entered into "Type Data" textarea one at line.

Multiple choices  - multiple choices from list, turns into list of keywords. List of values should be entered into "Type Data" textarea one at line.

File              - writes string into object and puts file into `< getcwd >/pub/upload/< model name >-< field name >/`

Single relation   - used in few cases

    1. For a tree, when adding Single relation with name `parent` model will be automatically displayed as a tree and field will be used to connect branches.
      `tree-item-title` method can be implemented for a normal appearance

    2. For relation with a tree, in this case you should write tree model name into "Type Data" textarea. 
      `weblocks-cms:tree-item-title` method can be implemented for a normal appearance

    3. For relation with other model, not a tree, in this case you should write model name into "Type Data" textarea.
      `weblocks-cms:bootstrap-typeahead-title` method can be implemented for a normal appearance
