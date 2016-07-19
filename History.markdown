## 1.3.3 / 2016-07-19

  * Rename `revision` to `rev` to avoid collision with Capistrano method (#22)

## 1.3.2 / 2015-11-03

  * using ls-remote instead of rev-parse to fetch revision (#19)

## 1.3.1 / 2015-05-13

  * Fix missing emoji for color-enabled messages (#14)

## 1.3.0 / 2015-03-05

  * Don't show empty () if no revision found (#10)
  * Introduce `slack_destination` which can override the stage. (#12)

## 1.2.0 / 2015-02-27

  * Allow colored output to notifications (#9)
  * Add a `slack:failed` task. (#7)
  * Add the revision to the deploy stage message. (#6)
  * Remove default `before` and `after` hooks (#4)

## 1.1.0 / 2015-02-11

  * Override the application name with `:slack_app_name` (#1)

## 1.0.0 / 2015-02-06

  * Birthday!
