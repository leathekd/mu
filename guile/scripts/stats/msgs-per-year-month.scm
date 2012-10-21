#!/bin/sh
exec guile -e main -s $0 $@
!#
;;
;; Copyright (C) 2012 Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 3, or (at your option) any
;; later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software Foundation,
;; Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

;; DESCRIPTION: number of messages per year-month

(use-modules (mu) (mu script) (mu stats) (mu plot))

(define (per-year-month expr text-only)
  "Count the total number of messages for each weekday (0-6 for
Sun..Sat) that match EXPR. If PLAIN-TEXT is true, use a plain-text
display, otherwise, use a graphical window."
  (mu:plot
    (sort (mu:tabulate
	    (lambda (msg)
	      (string->number
		(format #f "~d~2'0d"
		  (+ 1900 (tm:year (localtime (mu:date msg))))
		  (tm:mon (localtime (mu:date msg))))))
	    expr)
      (lambda (x y) (< (car x) (car y))))
    (format #f "Messages per year/month matching ~a" expr)
    "Year/Month" "Messages" text-only))

(define (main args)
  (mu:run args per-year-month))

;; Local Variables:
;; mode: scheme
;; End: