;;; mua-common.el -- part of mua, the mu mail user agent
;;
;; Copyright (C) 2011 Dirk-Jan C. Binnema

;; Author: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Maintainer: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Keywords: email
;; Version: 0.0

;; This file is not part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; mua-common contains common utility functions for mua

;;; Code:
 
(eval-when-compile (require 'cl))

(defconst mua/log-buffer-name "*mua-log*" "name of the logging buffer")

(defun mua/warn (frm &rest args)
  "warn user in echo-area, return nil"
  (let ((str (apply 'format frm args)))
    (message str)
    nil))

(defun mua/log (frm &rest args)
  "write something in the *mua-log* buffer - mainly useful for debugging"
  (with-current-buffer (get-buffer-create mua/log-buffer-name)
    (goto-char (point-max))
    (insert (apply 'format (concat (format-time-string "%x %X " (current-time))
			     frm "\n") args))))

(defun mua/warn-and-log (frm &rest args)
  "log and warn (ie., mua/warn + mua/log); return nil"
  (apply 'mua/log frm args)
  (apply 'mua/warn frm args)
  nil)

(defun mua/new-buffer (bufname)
  "return a new buffer BUFNAME; if such already exists, kill the
old one first"
  (when (get-buffer bufname)
    (kill-buffer bufname))
  (get-buffer-create bufname))

(defun mua/message (frm &rest args)
  "print a message at point"
  (let ((str (apply 'format frm args)) (inhibit-read-only t))
    (insert (propertize str 'face 'italic))))

(defun mua/quit-buffer ()
  "kill this buffer, and switch to it's parentbuf if it is alive"
  (interactive)  
  (let ((parentbuf mua/parent-buffer))
    (kill-buffer)
    (when (and parentbuf (buffer-live-p parentbuf))
      (switch-to-buffer parentbuf))))

(defun mua/ask-maildir (prompt &optional fullpath)
  "Ask user with PROMPT for a maildir name, if fullpath is
non-nill, return the fulpath (ie, mu-maildir prepended to the
maildir."
  (interactive)
  (let* ((showfolders
	     (append (list mua/inbox-folder mua/drafts-folder mua/sent-folder)
	       mua/working-folders))
	  (chosen (ido-completing-read prompt showfolders)))
    (concat (if fullpath mua/maildir "") chosen)))
	  
(defun mua/maildir-flags-from-path (path)
  "Get the flags for the message at PATH, which does not have to exist.
The flags are returned as a list consisting of one or more of
DFNPRST, mean resp. Deleted, Flagged, New, Passed Replied, Seen
and Trash, as defined in [1]. See `mua/maildir-string-to-flags'
and `mua/maildir-flags-to-string'.
\[1\]  http://cr.yp.to/proto/maildir.html." 
  (when (string-match ",\\(\[A-Z\]*\\)$" path)
    (mua/maildir-string-to-flags (match-string 1 path))))



(defun mua/maildir-from-path (path &optional dont-strip-prefix)
  "Get the maildir from path; in this context, 'maildir' is the
part between the `mua/maildir' and the /cur or /new; so
e.g. \"/home/user/Maildir/foo/bar/cur/12345:2,S\" would have
\"/foo/bar\" as its maildir. If DONT-STRIP-PREFIX is non-nil,
function will instead _not_ remove the `mua/maildir' from the
front - so in that case, the example would return
\"/home/user/Maildir/foo/bar/\". If the maildir cannot be
determined, return `nil'."
  (when (and (string-match "^\\(.*\\)/\\(cur\\|new\\)/\[^/\]*$" path))
    (let ((mdir (match-string 1 path)))	 
      (when (and (< (length mua/maildir) (length mdir))
	      (string= (substring mdir 0 (length mua/maildir)) mua/maildir))
	(if dont-strip-prefix
	  mdir
	  (substring mdir (length mua/maildir)))))))

;; TODO: ensure flag string have the chars in ASCII-order (as per maildir spec)
;; TODO: filter-out duplicate flags

(defun mua/maildir-flags-to-string (flags)
  "Convert a list of flags into a string as seen in Maildir
message files; flags are symbols draft, flagged, new, passed,
replied, seen, trashed and the string is the concatenation of the
uppercased first letters of these flags, as per [1]. Other flags
than the ones listed here are ignored.

Also see `mua/maildir-string-to-flags'.

\[1\]: http://cr.yp.to/proto/maildir.html"
  (when flags
    (let ((kar
	    (case (car flags) 
	      ('draft    ?D) 
	      ('flagged  ?F)
	      ('passed   ?P)
	      ('replied  ?R)
	      ('seen     ?S)
	      ('trashed  ?T))))
      (concat (and kar (string kar))
	(mua/maildir-flags-to-string (cdr flags))))))

(defun mua/maildir-string-to-flags (str)
  "Convert a string with message flags as seen in Maildir
messages into a list of flags in; flags are symbols draft,
flagged, new, passed, replied, seen, trashed and the string is
the concatenation of the uppercased first letters of these flags,
as per [1]. Other letters than the ones listed here are ignored.
Also see `mua/maildir-flags-to-string'.

\[1\]: http://cr.yp.to/proto/maildir.html"
  (when (/= 0 (length str))
    (let ((flag
	    (case (string-to-char str)
	      (?D   'draft)
	      (?F   'flagged)
	      (?P   'passed)
	      (?R   'replied)
	      (?S   'seen)
	      (?T   'trashed))))
      (append (when flag (list flag)) 
	(mua/maildir-string-to-flags (substring str 1))))))

(provide 'mua-common)