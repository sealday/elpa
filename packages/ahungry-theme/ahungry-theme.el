;;; ahungry-theme.el --- Ahungry color theme for Emacs.  Make sure to (load-theme 'ahungry).  -*- lexical-binding:t -*-

;; Copyright (C) 2015,2016  Free Software Foundation, Inc.

;; Author: Matthew Carter <m@ahungry.com>
;; Maintainer: Matthew Carter <m@ahungry.com>
;; URL: https://github.com/ahungry/color-theme-ahungry
;; Version: 1.2.0
;; Keywords: ahungry palette color theme emacs color-theme deftheme
;; Package-Requires: ((emacs "24"))

;; This file is part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Bright and bold color theme for GNU Emacs.

;; If you load it from a terminal, you will be able to make use of the
;; transparent background.  If you load it from a GUI, it will default
;; to a dark background.

;;; News:

;;;; Changes since 1.1.0:
;; - New variable ahungry-theme-font-settings to avoid overriding user font sizes
;; - Add info-mode faces

;;;; Changes since 1.0.12:
;; - Add erc/jabber faces to begin with

;;;; Changes since 1.0.11:
;; - Purple is too hard to read on poor contrast monitors, use a blue

;;;; Changes since 1.0.10:
;; - Add faces for powerline/spaceline setup
;; - Reduce org-mode heading sizes slightly

;;;; Changes since 1.0.9:
;; - Add/adjust some of the org-mode faces

;;;; Changes since 1.0.8:
;; - Add even more colors for magit 2.0 face names

;;;; Changes since 1.0.7:
;; - Add colors for magit 2.0 face names

;;;; Changes since 1.0.6:
;; - Remove warning producing call to "default" background color
;; - Add a color update for mm-uu-extract

;;;; Changes since 1.0.5:
;; - Add a few colors for helm (the defaults did not work well with this theme)

;;;; Changes since 1.0.4:
;; - Don't circumvent normal autoloads functionality, use the comment load method

;;;; Changes since 1.0.3:
;; - Manually include an autoloads file to make sure
;;   custom-theme-load-path is filled out
;; - Update description to make mention of (load-theme 'ahungry) for new users

;;; Code:

(deftheme ahungry
  "Ahungry Theme")

(defvar ahungry-theme-font-settings
  '(:family "Terminus" :foundry "xos4"
            :slant normal :weight normal
            :height 100 :width normal)
  "If set to nil, will avoid overriding the user font settings.
Leave this alone to retain defaults.

Default value:
  '(:family \"Terminus\" :foundry \"xos4\"
            :slant normal :weight normal
            :height 100 :width normal)")

(let ((mainbg (when (display-graphic-p) "#222222")));; "default")))
  (custom-theme-set-faces
   'ahungry ;; This is the theme name
   `(default ((t (:foreground "#ffffff" :background ,mainbg
                              ,@ahungry-theme-font-settings))))
   '(cursor ((t (:background "#fce94f" :foreground "#ffffff"))))
   '(highlight ((t (:background "brown4" :foreground nil))))
   '(border ((t (:background "#888a85"))))
   '(fringe ((t (:background "#333333"))))
   '(mode-line ((t (:foreground "#0022aa" :bold t :background "#77ff00"
                                :box (:line-width 1 :color nil :style released-button)))))
   '(mode-line-inactive ((t (:foreground "#444444" :background "#66ff33"))))
   '(mode-line-buffer-id ((t (:bold t :foreground "#ffffff" :background "#0055ff"))))
   '(powerline-active1 ((t (:foreground "#ffffff" :background "#222222"))))
   '(powerline-active2 ((t (:foreground "#ffffff" :background "#77ff00"))))
   '(powerline-inactive1 ((t (:foreground "#ffffff" :background "#555555"))))
   '(powerline-inactive2 ((t (:foreground "#ffffff" :background "#66ff33"))))
   '(spaceline-flycheck-error ((t (:foreground "#ff0066" :background "#333333"))))
   '(spaceline-flycheck-info ((t (:foreground "#ffaa00" :background "#333333"))))
   '(spaceline-flycheck-warning ((t (:foreground "#ffaa00" :background "#333333"))))
   '(region ((t (:background "#444444"))))
   '(link ((t (:underline t :foreground "#33ff99"))))
   '(custom-link ((t (:inherit 'link))))
   '(match ((t (:bold t :background "#e9b96e" :foreground "#2e3436"))))
   '(tool-tips ((t (:inherit 'variable-pitch :foreground "black" :background "#ffff33"))))
   '(tooltip ((t (:inherit 'variable-pitch :foreground "black" :background "#ffff33"))))
   '(bold ((t (:bold t :underline nil :background nil))))
   '(italic ((t (:italic t :underline nil :background nil))))
   '(font-lock-builtin-face ((t (:foreground "#0055ff"))))
   '(font-lock-comment-face ((t (:foreground "#888a85" :bold nil :italic t))))
   '(font-lock-constant-face ((t (:foreground "#fff900"))))
   '(font-lock-doc-face ((t (:foreground "#777700" :bold t :italic t))))
   '(font-lock-keyword-face ((t (:foreground "#3cff00" :bold t))))
   '(font-lock-string-face ((t (:foreground "#ff0077" :italic nil :bold nil))))
   '(font-lock-type-face ((t (:foreground "#deff00" :bold t))))
   '(font-lock-variable-name-face ((t (:foreground "#0033ff" :bold t))))
   '(font-lock-warning-face ((t (:bold t :foreground "#ff0000"))))
   '(font-lock-function-name-face ((t (:foreground "#ffee00" :bold t))))
   '(comint-highlight-input ((t (:italic t :bold t))))
   '(comint-highlight-prompt ((t (:foreground "#33cc33"))))
   '(diff-header ((t (:background "#444444"))))
   '(diff-index ((t (:foreground "#ffff00" :bold t))))
   '(diff-file-header ((t (:foreground "#aaaaaa" :bold t))))
   '(diff-hunk-header ((t (:foreground "#ffff00"))))
   '(diff-added ((t (:background "default" :foreground "#00ff00" :weight normal))))
   '(diff-removed ((t (:background "default" :foreground "#ff0000" :weight normal))))
   '(diff-context ((t (:foreground "#777777"))))
   '(diff-refine-change ((t (:bold t :background "#444444"))))
   '(isearch ((t (:background "#ff6600" :foreground "#333333"))))
   '(isearch-lazy-highlight-face ((t (:foreground "#2e3436" :background "#ff6600"))))
   '(show-paren-match-face ((t (:background "#ff6600" :foreground "#2e3436"))))
   '(show-paren-mismatch-face ((t (:background "#999999" :foreground "#ff6600"))))
   '(diary ((t (:bold t :foreground "#ff0000"))))
   '(message-cited-text ((t (:foreground "#ffc800"))))
   '(gnus-cite-1 ((t (:foreground "#999999"))))
   '(gnus-cite-2 ((t (:foreground "#cba559"))))
   '(gnus-cite-3 ((t (:foreground "#83ae92"))))
   '(gnus-cite-4 ((t (:foreground "#6898a7"))))
   '(gnus-cite-face-1 ((t (:foreground "#999999"))))
   '(gnus-cite-face-2 ((t (:foreground "#cba559"))))
   '(gnus-cite-face-3 ((t (:foreground "#83ae92"))))
   '(gnus-cite-face-4 ((t (:foreground "#6898a7"))))
   '(gnus-group-mail-1-empty ((t (:foreground "#009955"))))
   '(gnus-group-mail-1 ((t (:bold t :foreground "#ff9900"))))
   '(gnus-group-mail-2-empty ((t (:foreground "#009955"))))
   '(gnus-group-mail-2 ((t (:bold t :foreground "#ffaa00"))))
   '(gnus-group-mail-3-empty ((t (:foreground "#009955"))))
   '(gnus-group-mail-3 ((t (:bold t :foreground "#ffcc00"))))
   '(gnus-group-mail-low-empty ((t (:foreground "#009955"))))
   '(gnus-group-mail-low ((t (:bold t :foreground "#005fff"))))
   '(gnus-group-news-1-empty ((t (:foreground "#009955"))))
   '(gnus-group-news-1 ((t (:bold t :foreground "#ff9900"))))
   '(gnus-group-news-2-empty ((t (:foreground "#009955"))))
   '(gnus-group-news-2 ((t (:bold t :foreground "#ffaa00"))))
   '(gnus-group-news-3-empty ((t (:foreground "#009955"))))
   '(gnus-group-news-3 ((t (:bold t :foreground "#ffcc00"))))
   '(gnus-group-news-low-empty ((t (:foreground "#009955"))))
   '(gnus-group-news-low ((t (:bold t :foreground "#005fff"))))
   '(gnus-header-name ((t (:bold t :foreground "#33ffbb"))))
   '(gnus-header-from ((t (:bold t :foreground "#ffc800"))))
   '(gnus-header-subject ((t (:foreground "#ffc800"))))
   '(gnus-header-content ((t (:italic t :foreground "#33cc33"))))
   '(gnus-header-newsgroups ((t (:italic t :bold t :foreground "#0088ff"))))
   '(gnus-signature ((t (:italic t :foreground "#666666"))))
   '(gnus-summary-cancelled ((t (:background "#222222" :foreground "#ffff00"))))
   '(gnus-summary-high-ancient ((t (:bold t :foreground "#0099ff"))))
   '(gnus-summary-high-read ((t (:bold t :foreground "#33ff99"))))
   '(gnus-summary-high-ticked ((t (:bold t :foreground "#f68585"))))
   '(gnus-summary-high-unread ((t (:bold t :foreground "#ffffff"))))
   '(gnus-summary-low-ancient ((t (:italic t :foreground "#33ff99"))))
   '(gnus-summary-low-read ((t (:italic t :foreground "#0099ff"))))
   '(gnus-summary-low-ticked ((t (:italic t :foreground "#ff3333"))))
   '(gnus-summary-low-unread ((t (:italic t :foreground "#ffffff"))))
   '(gnus-summary-normal-ancient ((t (:foreground "#0099ff"))))
   '(gnus-summary-normal-read ((t (:foreground "#33ff99"))))
   '(gnus-summary-normal-ticked ((t (:foreground "#ff0000"))))
   '(gnus-summary-normal-unread ((t (:foreground "#ffffff"))))
   '(gnus-summary-selected ((t (:background "brown4" :foreground "#ffffff"))))
   '(message-header-name ((t (:foreground "#f68585"))))
   '(message-header-newsgroups ((t (:italic t :bold t :foreground "#0088ff"))))
   '(message-header-other ((t (:foreground "#0088ff"))))
   '(message-header-xheader ((t (:foreground "#0088ff"))))
   '(message-header-subject ((t (:foreground "#ffffff"))))
   '(message-header-to ((t (:foreground "#ffffff"))))
   '(message-header-cc ((t (:foreground "#ffffff"))))
   '(mm-uu-extract ((t (:foreground "#0066ff"))))
   '(org-hide ((t (:foreground "#222222"))))
   '(org-level-1 ((t (:bold t :foreground "#4477ff" :height 1.4))))
   '(org-level-2 ((t (:bold nil :foreground "#ffc800" :height 1.1))))
   '(org-level-3 ((t (:bold t :foreground "#00aa33" :height 1.0))))
   '(org-level-4 ((t (:bold nil :foreground "#f68585" :height 1.0))))
   '(org-date ((t (:underline t :foreground "#ff0066"))))
   '(org-footnote  ((t (:underline t :foreground "#ff0066"))))
   '(org-link ((t (:foreground "skyblue2" :background "#2e3436"))))
   '(org-special-keyword ((t (:foreground "#cc0033"))))
   '(org-verbatim ((t (:foreground "#cc6600" :underline t :slant italic))))
   '(org-block ((t (:foreground "#999999"))))
   '(org-quote ((t (:inherit org-block :bold t :slant italic))))
   '(org-verse ((t (:inherit org-block :bold t :slant italic))))
   '(org-table ((t (:foreground "#0055ff"))))
   '(org-todo ((t (:bold t :foreground "#ff0099"))))
   '(org-done ((t (:bold t :foreground "#00cc33"))))
   '(org-agenda-structure ((t (:weight bold :foreground "#f68585"))))
   '(org-agenda-date ((t (:foreground "#00ff55"))))
   '(org-agenda-date-weekend ((t (:weight normal :foreground "#005fff"))))
   '(org-agenda-date-today ((t (:weight bold :foreground "#ffc800"))))
   '(org-agenda-done ((t (:weight normal :foreground "#00aa33"))))
   '(org-block-begin-line ((t (:foreground "#bbbbbb" :background "#333333"))))
   '(org-block-background ((t (:background "#333333"))))
   '(org-block-end-line ((t (:foreground "#bbbbbb" :background "#333333"))))
   '(org-document-title ((t (:weight bold :foreground "#0077cc"))))
   '(org-document-info ((t (:weight normal :foreground "#0077cc"))))
   '(org-document-info-keyword ((t (:weight normal :foreground "#aaaaaa"))))
   '(org-warning ((t (:weight normal :foreground "#ee0033"))))
   '(magit-hash ((t (:foreground "#6699aa"))))
   '(magit-branch-local ((t (:foreground "#0066ff"))))
   '(magit-branch-remote ((t (:foreground "#ffcc44"))))
   '(magit-diffstat-added ((t (:foreground "#00ff66"))))
   '(magit-diff-added-highlight ((t (:foreground "#33ff00" :weight normal))))
   '(magit-diff-added ((t (:foreground "#44aa00" :weight normal))))
   '(magit-diff-removed-highlight ((t (:foreground "#ff0033" :weight normal))))
   '(magit-diff-removed ((t (:foreground "#aa0044" :weight normal))))
   '(magit-diff-hunk-heading ((t (:foreground "#aaaa00"))))
   '(magit-diff-hunk-heading-highlight ((t (:foreground "#ffff00"))))
   '(magit-diffstat-removed ((t (:foreground "#ff0066"))))
   '(magit-diff-context-highlight ((t (:foreground "#ffffff"))))
   '(magit-section-heading ((t (:foreground "#ff0066"))))
   '(magit-section-highlight ((t (:weight bold))));;:foreground "#ffffff"))))
   '(minibuffer-prompt ((t (:foreground "#0055ff" :bold t))))
   '(web-mode-html-tag-bracket-face ((t (:foreground "#666666"))))
   '(helm-selection ((t (:foreground "#ff0099" :italic t :bold t :background "#f2e997"))))
   '(helm-match ((t (:foreground "gold1"))))
   '(helm-visible-mark ((t (:background "#f2e997" :foreground "#ff0099" :bold nil :italic nil))))
   '(erc-nick-default-face ((t (:foreground "#ff0099"))))
   '(erc-current-nick-face ((t (:foreground "#0099ff"))))
   '(erc-input-face ((t (:foreground "#0099ff"))))
   '(erc-prompt-face ((t (:background nil :foreground "#666666" :bold t :italic t))))
   '(erc-timestamp-face ((t (:background nil :foreground "#666666" :bold nil :italic t))))
   '(jabber-chat-prompt-foreign ((t (:foreground "#ff0099"))))
   '(jabber-chat-prompt-local ((t (:foreground "#0099ff"))))
   '(jabber-rare-time-face ((t (:foreground "#666666" :bold nil :italic t))))
   '(eshell-prompt ((t (:foreground "#0099ff"))))
   '(info-menu-header ((t (:foreground "#0099ff" :bold t :underline t))))
   '(info-header-xref ((t (:foreground "#0099ff"))))
   '(info-header-node ((t (:foreground "#ff0099" :bold t :italic t))))
   '(info-menu-star ((t (:foreground "#0099ff" :bold t))))
   '(info-xref-visited ((t (:foreground "#999999"))))
   '(info-xref ((t (:foreground "#0099ff"))))
   '(info-node ((t (:foreground "#ff0099"))))
   '(info-title-1 ((t (:foreground "yellow" :bold t))))
   '(info-title-2 ((t (:foreground "#ff0099"))))
   )
  (custom-theme-set-variables
   'ahungry
   '(red "#ffffff"))
  )

;;;###autoload
(when (and load-file-name (boundp 'custom-theme-load-path))
 (add-to-list
      'custom-theme-load-path
      (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'ahungry)

;;; ahungry-theme.el ends here
