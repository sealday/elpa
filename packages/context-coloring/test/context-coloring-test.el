;;; test/context-coloring-test.el --- Tests for context coloring. -*- lexical-binding: t; -*-

;; Copyright (C) 2014-2015  Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Tests for context-coloring.

;; Tests for both synchronous (elisp) and asynchronous (shell command) coloring
;; are available.  Basic plugin functionality is also tested.

;; To run, execute `make test' from the project root.

;;; Code:

(require 'context-coloring)
(require 'ert-async)
(require 'js2-mode)


;;; Test running utilities

(defconst context-coloring-test-path
  (file-name-directory (or load-file-name buffer-file-name))
  "This file's directory.")

(defun context-coloring-test-read-file (path)
  "Read a file's contents from PATH into a string."
  (with-temp-buffer
    (insert-file-contents (expand-file-name path context-coloring-test-path))
    (buffer-string)))

(defun context-coloring-test-setup ()
  "Prepare before all tests."
  (setq context-coloring-comments-and-strings nil))

(defun context-coloring-test-cleanup ()
  "Cleanup after all tests."
  (setq context-coloring-comments-and-strings t)
  (setq context-coloring-syntactic-comments nil)
  (setq context-coloring-syntactic-strings nil)
  (setq context-coloring-js-block-scopes nil)
  (setq context-coloring-check-scopifier-version-hook nil))

(defmacro context-coloring-test-with-fixture (fixture &rest body)
  "With the relative FIXTURE, evaluate BODY in a temporary
buffer."
  `(with-temp-buffer
     (unwind-protect
         (progn
           (context-coloring-test-setup)
           (insert (context-coloring-test-read-file ,fixture))
           ,@body)
       (context-coloring-test-cleanup))))

(defun context-coloring-test-with-temp-buffer-async (callback)
  "Create a temporary buffer, and evaluate CALLBACK there.  A
teardown callback is passed to CALLBACK for it to invoke when it
is done."
  (let ((previous-buffer (current-buffer))
        (temp-buffer (generate-new-buffer " *temp*")))
    (set-buffer temp-buffer)
    (funcall
     callback
     (lambda ()
       (and (buffer-name temp-buffer)
            (kill-buffer temp-buffer))
       (set-buffer previous-buffer)))))

(defun context-coloring-test-with-fixture-async
    (fixture callback &optional setup)
  "With the relative FIXTURE, evaluate CALLBACK in a temporary
buffer.  A teardown callback is passed to CALLBACK for it to
invoke when it is done.  An optional SETUP callback can run
arbitrary code before the mode is invoked."
  (context-coloring-test-with-temp-buffer-async
   (lambda (done-with-temp-buffer)
     (context-coloring-test-setup)
     (when setup (funcall setup))
     (insert (context-coloring-test-read-file fixture))
     (funcall
      callback
      (lambda ()
        (context-coloring-test-cleanup)
        (funcall done-with-temp-buffer))))))


;;; Test defining utilities

(defun context-coloring-test-js-mode (fixture callback &optional setup)
  "Use FIXTURE as the subject matter for test logic in CALLBACK.
Optionally, provide setup code to run before the mode is
instantiated in SETUP."
  (context-coloring-test-with-fixture-async
   fixture
   (lambda (done-with-test)
     (js-mode)
     (context-coloring-mode)
     (context-coloring-colorize
      (lambda ()
        (funcall callback done-with-test))))
   setup))

(defmacro context-coloring-test-js2-mode (fixture setup &rest body)
  "Use FIXTURE as the subject matter for test logic in BODY."
  `(context-coloring-test-with-fixture
    ,fixture
    (require 'js2-mode)
    (setq js2-mode-show-parse-errors nil)
    (setq js2-mode-show-strict-warnings nil)
    (js2-mode)
    (when ,setup (funcall ,setup))
    (context-coloring-mode)
    ,@body))

(cl-defmacro context-coloring-test-deftest-js-mode (name &key fixture-name)
  "Define an asynchronous test for `js-mode' with the name NAME
in the typical format."
  (declare (indent defun))
  (let ((test-name (intern (format "context-coloring-test-js-mode-%s" name)))
        (fixture (format "./fixtures/%s.js" (or fixture-name name)))
        (function-name (intern-soft
                        (format "context-coloring-test-js-%s" name)))
        (setup-function-name (intern-soft
                              (format
                               "context-coloring-test-js-%s-setup" name))))
    `(ert-deftest-async ,test-name (done)
                        (context-coloring-test-js-mode
                         ,fixture
                         (lambda (teardown)
                           (unwind-protect
                               (,function-name)
                             (funcall teardown))
                           (funcall done))
                         ',setup-function-name))))

(cl-defmacro context-coloring-test-deftest-js2-mode (name &key fixture-name)
  "Define a test for `js2-mode' with the name NAME in the typical
format."
  (declare (indent defun))
  (let ((test-name (intern (format "context-coloring-test-js2-mode-%s" name)))
        (fixture (format "./fixtures/%s.js" (or fixture-name name)))
        (function-name (intern-soft
                        (format "context-coloring-test-js-%s" name)))
        (setup-function-name (intern-soft
                              (format
                               "context-coloring-test-js-%s-setup" name))))
    `(ert-deftest ,test-name ()
       (context-coloring-test-js2-mode
        ,fixture
        ',setup-function-name
        (,function-name)))))


;;; Assertion functions

(defmacro context-coloring-test-assert-region (&rest body)
  "Assert something about the face of points in a region.
Provides the free variables `i', `length', `point', `face' and
`actual-level' to the code in BODY."
  `(let ((i 0)
         (length (- end start)))
     (while (< i length)
       (let* ((point (+ i start))
              (face (get-text-property point 'face)))
         ,@body)
       (setq i (+ i 1)))))

(defun context-coloring-test-assert-region-level (start end level)
  "Assert that all points in the range [START, END) are of level
LEVEL."
  (context-coloring-test-assert-region
   (let (actual-level)
     (when (not (when face
                  (let* ((face-string (symbol-name face))
                         (matches (string-match
                                   context-coloring-level-face-regexp
                                   face-string)))
                    (when matches
                      (setq actual-level (string-to-number
                                          (substring face-string
                                                     (match-beginning 1)
                                                     (match-end 1))))
                      (= level actual-level)))))
       (ert-fail (format (concat "Expected level in region [%s, %s), "
                                 "which is \"%s\", to be %s; "
                                 "but at point %s, it was %s")
                         start end
                         (buffer-substring-no-properties start end) level
                         point actual-level))))))

(defun context-coloring-test-assert-region-face (start end expected-face)
  "Assert that all points in the range [START, END) have the face
EXPECTED-FACE."
  (context-coloring-test-assert-region
   (when (not (eq face expected-face))
     (ert-fail (format (concat "Expected face in region [%s, %s), "
                               "which is \"%s\", to be %s; "
                               "but at point %s, it was %s")
                       start end
                       (buffer-substring-no-properties start end) expected-face
                       point face)))))

(defun context-coloring-test-assert-region-comment-delimiter (start end)
  "Assert that all points in the range [START, END) have
`font-lock-comment-delimiter-face'."
  (context-coloring-test-assert-region-face
   start end 'font-lock-comment-delimiter-face))

(defun context-coloring-test-assert-region-comment (start end)
  "Assert that all points in the range [START, END) have
`font-lock-comment-face'."
  (context-coloring-test-assert-region-face
   start end 'font-lock-comment-face))

(defun context-coloring-test-assert-region-string (start end)
  "Assert that all points in the range [START, END) have
`font-lock-string-face'."
  (context-coloring-test-assert-region-face
   start end 'font-lock-string-face))

(defun context-coloring-test-assert-message (expected buffer)
  "Assert that message EXPECTED exists in BUFFER."
  (when (null (get-buffer buffer))
    (ert-fail
     (format
      (concat
       "Expected buffer `%s' to have message \"%s\", "
       "but the buffer did not have any messages.")
      buffer expected)))
  (with-current-buffer buffer
    (let ((messages (split-string
                     (buffer-substring-no-properties
                      (point-min)
                      (point-max))
                     "\n")))
      (let ((message (car (nthcdr (- (length messages) 2) messages))))
        (when (not (equal message expected))
          (ert-fail
           (format
            (concat
             "Expected buffer `%s' to have message \"%s\", "
             "but instead it was \"%s\"")
            buffer expected
            message)))))))

(defun context-coloring-test-assert-no-message (buffer)
  "Assert that BUFFER has no message."
  (when (get-buffer buffer)
    (ert-fail (format (concat "Expected buffer `%s' to have no messages, "
                              "but it did: `%s'")
                      buffer
                      (with-current-buffer buffer
                        (buffer-string))))))

(defun context-coloring-test-kill-buffer (buffer)
  "Kill BUFFER if it exists."
  (when (get-buffer buffer) (kill-buffer buffer)))

(defun context-coloring-test-assert-face (level foreground &optional negate)
  "Assert that a face for LEVEL exists and that its `:foreground'
is FOREGROUND, or the inverse if NEGATE is non-nil."
  (let* ((face (context-coloring-level-face level))
         actual-foreground)
    (when (not (or negate
                   face))
      (ert-fail (format (concat "Expected face for level `%s' to exist; "
                                "but it didn't")
                        level)))
    (setq actual-foreground (face-attribute face :foreground))
    (when (funcall (if negate 'identity 'not)
                   (string-equal foreground actual-foreground))
      (ert-fail (format (concat "Expected face for level `%s' "
                                "%sto have foreground `%s'; "
                                "but it %s.")
                        level
                        (if negate "not " "") foreground
                        (if negate
                            "did" (format "was `%s'" actual-foreground)))))))

(defun context-coloring-test-assert-not-face (&rest arguments)
  "Assert that LEVEL does not have a face with `:foreground'
FOREGROUND.  Apply ARGUMENTS to
`context-coloring-test-assert-face', see that function."
  (apply 'context-coloring-test-assert-face
         (append arguments '(t))))


;;; The tests

(ert-deftest context-coloring-test-unsupported-mode ()
  (context-coloring-test-with-fixture
   "./fixtures/function-scopes.js"
   (context-coloring-mode)
   (context-coloring-test-assert-message
    "Context coloring is not available for this major mode"
    "*Messages*")))

(define-derived-mode
  context-coloring-test-unsupported-version-mode
  fundamental-mode
  "Testing"
  "Prevent `context-coloring-test-unsupported-version' from
  having any unintentional side-effects on mode support.")

(ert-deftest-async context-coloring-test-unsupported-version (done)
  (context-coloring-define-dispatch
   'outta-date
   :modes '(context-coloring-test-unsupported-version-mode)
   :executable "node"
   :command "node test/binaries/outta-date"
   :version "v2.1.3")
  (context-coloring-test-with-fixture-async
   "./fixtures/function-scopes.js"
   (lambda (teardown)
     (context-coloring-test-unsupported-version-mode)
     (add-hook
      'context-coloring-check-scopifier-version-hook
      (lambda ()
        (unwind-protect
            (progn
              ;; Normally the executable would be something like "outta-date"
              ;; rather than "node".
              (context-coloring-test-assert-message
               "Update to the minimum version of \"node\" (v2.1.3)"
               "*Messages*"))
          (funcall teardown))
        (funcall done)))
     (context-coloring-mode))))

(defvar context-coloring-test-theme-index 0
  "Unique index for unique theme names.")

(defun context-coloring-test-get-next-theme ()
  "Return a unique symbol for a throwaway theme."
  (prog1
      (intern (format "context-coloring-test-theme-%s"
                      context-coloring-test-theme-index))
    (setq context-coloring-test-theme-index
          (+ context-coloring-test-theme-index 1))))

(defun context-coloring-test-assert-theme-originally-set-p
    (settings &optional negate)
  "Assert that `context-coloring-theme-originally-set-p' returns
t for a theme with SETTINGS, or the inverse if NEGATE is
non-nil."
  (let ((theme (context-coloring-test-get-next-theme)))
    (put theme 'theme-settings settings)
    (when (funcall (if negate 'identity 'not)
                   (context-coloring-theme-originally-set-p theme))
      (ert-fail (format (concat "Expected theme `%s' with settings `%s' "
                                "%sto be considered to have defined a level, "
                                "but it %s.")
                        theme settings
                        (if negate "not " "")
                        (if negate "was" "wasn't"))))))

(defun context-coloring-test-assert-not-theme-originally-set-p (&rest arguments)
  "Assert that `context-coloring-theme-originally-set-p' does not
return t for a theme with SETTINGS.  Apply ARGUMENTS to
`context-coloring-test-assert-theme-originally-set-p', see that
function."
  (apply 'context-coloring-test-assert-theme-originally-set-p
         (append arguments '(t))))

(ert-deftest context-coloring-test-theme-originally-set-p ()
  (context-coloring-test-assert-theme-originally-set-p
   '((theme-face context-coloring-level-0-face)))
  (context-coloring-test-assert-theme-originally-set-p
   '((theme-face face)
     (theme-face context-coloring-level-0-face)))
  (context-coloring-test-assert-theme-originally-set-p
   '((theme-face context-coloring-level-0-face)
     (theme-face face)))
  (context-coloring-test-assert-not-theme-originally-set-p
   '((theme-face face)))
  )

(defun context-coloring-test-assert-theme-settings-highest-level
    (settings expected-level)
  "Assert that a theme with SETTINGS has the highest level
EXPECTED-LEVEL."
  (let ((theme (context-coloring-test-get-next-theme)))
    (put theme 'theme-settings settings)
    (context-coloring-test-assert-theme-highest-level theme expected-level)))

(defun context-coloring-test-assert-theme-highest-level
    (theme expected-level &optional negate)
  "Assert that THEME has the highest level EXPECTED-LEVEL, or the
inverse if NEGATE is non-nil."
  (let ((highest-level (context-coloring-theme-highest-level theme)))
    (when (funcall (if negate 'identity 'not) (eq highest-level expected-level))
      (ert-fail (format (concat "Expected theme with settings `%s' "
                                "%sto have a highest level of `%s', "
                                "but it %s.")
                        (get theme 'theme-settings)
                        (if negate "not " "") expected-level
                        (if negate "did" (format "was %s" highest-level)))))))

(defun context-coloring-test-assert-theme-not-highest-level (&rest arguments)
  "Assert that THEME's highest level is not EXPECTED-LEVEL.
Apply ARGUMENTS to
`context-coloring-test-assert-theme-highest-level', see that
function."
  (apply 'context-coloring-test-assert-theme-highest-level
         (append arguments '(t))))

(ert-deftest context-coloring-test-theme-highest-level ()
  (context-coloring-test-assert-theme-settings-highest-level
   '((theme-face foo))
   -1)
  (context-coloring-test-assert-theme-settings-highest-level
   '((theme-face context-coloring-level-0-face))
   0)
  (context-coloring-test-assert-theme-settings-highest-level
   '((theme-face context-coloring-level-1-face))
   1)
  (context-coloring-test-assert-theme-settings-highest-level
   '((theme-face context-coloring-level-1-face)
     (theme-face context-coloring-level-0-face))
   1)
  (context-coloring-test-assert-theme-settings-highest-level
   '((theme-face context-coloring-level-0-face)
     (theme-face context-coloring-level-1-face))
   1)
  )

(defmacro context-coloring-test-deftest-define-theme (name &rest body)
  "Define a test with name NAME and an automatically-generated
theme symbol available as a free variable `theme'.  Side-effects
from enabling themes are reversed after BODY is executed and the
test completes."
  (declare (indent defun))
  (let ((deftest-name (intern
                       (format "context-coloring-test-define-theme-%s" name))))
    `(ert-deftest ,deftest-name ()
       (context-coloring-test-kill-buffer "*Warnings*")
       (let ((theme (context-coloring-test-get-next-theme)))
         (unwind-protect
             (progn
               ,@body)
           ;; Always cleanup.
           (disable-theme theme))))))

(defun context-coloring-test-deftheme (theme)
  "Dynamically define theme THEME."
  (eval (macroexpand `(deftheme ,theme))))

(context-coloring-test-deftest-define-theme additive
  (context-coloring-test-deftheme theme)
  (context-coloring-define-theme
   theme
   :colors '("#aaaaaa"
             "#bbbbbb"))
  (context-coloring-test-assert-no-message "*Warnings*")
  (enable-theme theme)
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb"))

(defun context-coloring-test-assert-defined-warning (theme)
  "Assert that a warning about colors already being defined for
theme THEME is signaled."
  (context-coloring-test-assert-message
   (format (concat "Warning (emacs): Context coloring colors for theme "
                   "`%s' are already defined")
           theme)
   "*Warnings*"))

(context-coloring-test-deftest-define-theme unintentional-override
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(context-coloring-level-0-face ((t (:foreground "#aaaaaa"))))
   '(context-coloring-level-1-face ((t (:foreground "#bbbbbb")))))
  (context-coloring-define-theme
   theme
   :colors '("#cccccc"
             "#dddddd"))
  (context-coloring-test-assert-defined-warning theme)
  (context-coloring-test-kill-buffer "*Warnings*")
  (enable-theme theme)
  (context-coloring-test-assert-defined-warning theme)
  (context-coloring-test-assert-face 0 "#cccccc")
  (context-coloring-test-assert-face 1 "#dddddd"))

(context-coloring-test-deftest-define-theme intentional-override
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(context-coloring-level-0-face ((t (:foreground "#aaaaaa"))))
   '(context-coloring-level-1-face ((t (:foreground "#bbbbbb")))))
  (context-coloring-define-theme
   theme
   :override t
   :colors '("#cccccc"
             "#dddddd"))
  (context-coloring-test-assert-no-message "*Warnings*")
  (enable-theme theme)
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#cccccc")
  (context-coloring-test-assert-face 1 "#dddddd"))

(context-coloring-test-deftest-define-theme pre-recede
  (context-coloring-define-theme
   theme
   :recede t
   :colors '("#aaaaaa"
             "#bbbbbb"))
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(context-coloring-level-0-face ((t (:foreground "#cccccc"))))
   '(context-coloring-level-1-face ((t (:foreground "#dddddd")))))
  (enable-theme theme)
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#cccccc")
  (context-coloring-test-assert-face 1 "#dddddd"))

(context-coloring-test-deftest-define-theme post-recede
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(context-coloring-level-0-face ((t (:foreground "#aaaaaa"))))
   '(context-coloring-level-1-face ((t (:foreground "#bbbbbb")))))
  (context-coloring-define-theme
   theme
   :recede t
   :colors '("#cccccc"
             "#dddddd"))
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb")
  (enable-theme theme)
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb"))

(context-coloring-test-deftest-define-theme recede-not-defined
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(foo-face ((t (:foreground "#ffffff")))))
  (context-coloring-define-theme
   theme
   :recede t
   :colors '("#aaaaaa"
             "#bbbbbb"))
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb")
  (enable-theme theme)
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb"))

(context-coloring-test-deftest-define-theme unintentional-obstinance
  (context-coloring-define-theme
   theme
   :colors '("#aaaaaa"
             "#bbbbbb"))
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(context-coloring-level-0-face ((t (:foreground "#cccccc"))))
   '(context-coloring-level-1-face ((t (:foreground "#dddddd")))))
  (enable-theme theme)
  (context-coloring-test-assert-defined-warning theme)
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb"))

(context-coloring-test-deftest-define-theme intentional-obstinance
  (context-coloring-define-theme
   theme
   :override t
   :colors '("#aaaaaa"
             "#bbbbbb"))
  (context-coloring-test-deftheme theme)
  (custom-theme-set-faces
   theme
   '(context-coloring-level-0-face ((t (:foreground "#cccccc"))))
   '(context-coloring-level-1-face ((t (:foreground "#dddddd")))))
  (enable-theme theme)
  (context-coloring-test-assert-no-message "*Warnings*")
  (context-coloring-test-assert-face 0 "#aaaaaa")
  (context-coloring-test-assert-face 1 "#bbbbbb"))

(defun context-coloring-test-assert-maximum-face (maximum &optional negate)
  "Assert that `context-coloring-maximum-face' is MAXIMUM, or the
inverse if NEGATE is non-nil."
  (when (funcall (if negate 'identity 'not)
                 (eq context-coloring-maximum-face maximum))
    (ert-fail (format (concat "Expected `context-coloring-maximum-face' "
                              "%sto be `%s', "
                              "but it %s.")
                      (if negate "not " "") maximum
                      (if negate
                          "was"
                        (format "was `%s'" context-coloring-maximum-face))))))

(defun context-coloring-test-assert-not-maximum-face (&rest arguments)
  "Assert that `context-coloring-maximum-face' is not MAXIMUM.
Apply ARGUMENTS to `context-coloring-test-assert-maximum-face',
see that function."
  (apply 'context-coloring-test-assert-maximum-face
         (append arguments '(t))))

(context-coloring-test-deftest-define-theme disable-cascade
  (context-coloring-test-deftheme theme)
  (context-coloring-define-theme
   theme
   :colors '("#aaaaaa"
             "#bbbbbb"))
  (let ((second-theme (context-coloring-test-get-next-theme)))
    (context-coloring-test-deftheme second-theme)
    (context-coloring-define-theme
     second-theme
     :colors '("#cccccc"
               "#dddddd"
               "#eeeeee"))
    (let ((third-theme (context-coloring-test-get-next-theme)))
      (context-coloring-test-deftheme third-theme)
      (context-coloring-define-theme
       third-theme
       :colors '("#111111"
                 "#222222"
                 "#333333"
                 "#444444"))
      (enable-theme theme)
      (enable-theme second-theme)
      (enable-theme third-theme)
      (disable-theme third-theme)
      (context-coloring-test-assert-face 0 "#cccccc")
      (context-coloring-test-assert-face 1 "#dddddd")
      (context-coloring-test-assert-face 2 "#eeeeee")
      (context-coloring-test-assert-maximum-face 2))
    (disable-theme second-theme)
    (context-coloring-test-assert-face 0 "#aaaaaa")
    (context-coloring-test-assert-face 1 "#bbbbbb")
    (context-coloring-test-assert-maximum-face 1))
  (disable-theme theme)
  (context-coloring-test-assert-not-face 0 "#aaaaaa")
  (context-coloring-test-assert-not-face 1 "#bbbbbb")
  (context-coloring-test-assert-not-maximum-face 1))

(defun context-coloring-test-js-function-scopes ()
  "Test fixtures/functions-scopes.js."
  (context-coloring-test-assert-region-level 1 9 0)
  (context-coloring-test-assert-region-level 9 23 1)
  (context-coloring-test-assert-region-level 23 25 0)
  (context-coloring-test-assert-region-level 25 34 1)
  (context-coloring-test-assert-region-level 34 35 0)
  (context-coloring-test-assert-region-level 35 52 1)
  (context-coloring-test-assert-region-level 52 66 2)
  (context-coloring-test-assert-region-level 66 72 1)
  (context-coloring-test-assert-region-level 72 81 2)
  (context-coloring-test-assert-region-level 81 82 1)
  (context-coloring-test-assert-region-level 82 87 2)
  (context-coloring-test-assert-region-level 87 89 1))

(context-coloring-test-deftest-js-mode function-scopes)
(context-coloring-test-deftest-js2-mode function-scopes)

(defun context-coloring-test-js-global ()
  "Test fixtures/global.js."
  (context-coloring-test-assert-region-level 20 28 1)
  (context-coloring-test-assert-region-level 28 35 0)
  (context-coloring-test-assert-region-level 35 41 1))

(context-coloring-test-deftest-js-mode global)
(context-coloring-test-deftest-js2-mode global)

(defun context-coloring-test-js-block-scopes ()
  "Test fixtures/block-scopes.js."
  (context-coloring-test-assert-region-level 20 64 1)
   (setq context-coloring-js-block-scopes t)
   (context-coloring-colorize)
   (context-coloring-test-assert-region-level 20 27 1)
   (context-coloring-test-assert-region-level 27 41 2)
   (context-coloring-test-assert-region-level 41 42 1)
   (context-coloring-test-assert-region-level 42 64 2))

(context-coloring-test-deftest-js2-mode block-scopes)

(defun context-coloring-test-js-catch ()
  "Test fixtures/js-catch.js."
  (context-coloring-test-assert-region-level 20 27 1)
  (context-coloring-test-assert-region-level 27 51 2)
  (context-coloring-test-assert-region-level 51 52 1)
  (context-coloring-test-assert-region-level 52 73 2)
  (context-coloring-test-assert-region-level 73 101 3)
  (context-coloring-test-assert-region-level 101 102 1)
  (context-coloring-test-assert-region-level 102 117 3)
  (context-coloring-test-assert-region-level 117 123 2))

(context-coloring-test-deftest-js-mode catch)
(context-coloring-test-deftest-js2-mode catch)

(defun context-coloring-test-js-key-names ()
  "Test fixtures/key-names.js."
  (context-coloring-test-assert-region-level 20 63 1))

(context-coloring-test-deftest-js-mode key-names)
(context-coloring-test-deftest-js2-mode key-names)

(defun context-coloring-test-js-property-lookup ()
  "Test fixtures/property-lookup.js."
  (context-coloring-test-assert-region-level 20 26 0)
  (context-coloring-test-assert-region-level 26 38 1)
  (context-coloring-test-assert-region-level 38 44 0)
  (context-coloring-test-assert-region-level 44 52 1)
  (context-coloring-test-assert-region-level 57 63 0)
  (context-coloring-test-assert-region-level 63 74 1))

(context-coloring-test-deftest-js-mode property-lookup)
(context-coloring-test-deftest-js2-mode property-lookup)

(defun context-coloring-test-js-key-values ()
  "Test fixtures/key-values.js."
  (context-coloring-test-assert-region-level 78 79 1))

(context-coloring-test-deftest-js-mode key-values)
(context-coloring-test-deftest-js2-mode key-values)

(defun context-coloring-test-js-syntactic-comments-and-strings ()
  "Test comments and strings."
  (context-coloring-test-assert-region-level 1 8 0)
  (context-coloring-test-assert-region-comment-delimiter 9 12)
  (context-coloring-test-assert-region-comment 12 16)
  (context-coloring-test-assert-region-comment-delimiter 17 20)
  (context-coloring-test-assert-region-comment 20 27)
  (context-coloring-test-assert-region-string 28 40)
  (context-coloring-test-assert-region-level 40 41 0))

(defun context-coloring-test-js-syntactic-comments-and-strings-setup ()
  (setq context-coloring-syntactic-comments t)
  (setq context-coloring-syntactic-strings t))

(context-coloring-test-deftest-js-mode syntactic-comments-and-strings
  :fixture-name comments-and-strings)
(context-coloring-test-deftest-js2-mode syntactic-comments-and-strings
  :fixture-name comments-and-strings)

(defalias 'context-coloring-test-js-comments-and-strings
  'context-coloring-test-js-syntactic-comments-and-strings
  "Test comments and strings.  Deprecated.")

(defun context-coloring-test-js-comments-and-strings-setup ()
  "Setup comments and strings.  Deprecated."
  (setq context-coloring-comments-and-strings t))

(context-coloring-test-deftest-js-mode comments-and-strings)
(context-coloring-test-deftest-js2-mode comments-and-strings)

(defun context-coloring-test-js-syntactic-comments ()
  "Test syntactic comments."
  (context-coloring-test-assert-region-level 1 8 0)
  (context-coloring-test-assert-region-comment-delimiter 9 12)
  (context-coloring-test-assert-region-comment 12 16)
  (context-coloring-test-assert-region-comment-delimiter 17 20)
  (context-coloring-test-assert-region-comment 20 27)
  (context-coloring-test-assert-region-level 28 41 0))

(defun context-coloring-test-js-syntactic-comments-setup ()
  "Setup syntactic comments."
  (setq context-coloring-syntactic-comments t))

(context-coloring-test-deftest-js-mode syntactic-comments
  :fixture-name comments-and-strings)
(context-coloring-test-deftest-js2-mode syntactic-comments
  :fixture-name comments-and-strings)

(defun context-coloring-test-js-syntactic-strings ()
  "Test syntactic strings."
  (context-coloring-test-assert-region-level 1 28 0)
  (context-coloring-test-assert-region-string 28 40)
  (context-coloring-test-assert-region-level 40 41 0))

(defun context-coloring-test-js-syntactic-strings-setup ()
  "Setup syntactic strings."
  (setq context-coloring-syntactic-strings t))

(context-coloring-test-deftest-js-mode syntactic-strings
  :fixture-name comments-and-strings)
(context-coloring-test-deftest-js2-mode syntactic-strings
  :fixture-name comments-and-strings)

(provide 'context-coloring-test)

;;; context-coloring-test.el ends here