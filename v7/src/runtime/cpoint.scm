#| -*-Scheme-*-

$Id: cpoint.scm,v 14.9 2005/02/08 04:17:06 cph Exp $

Copyright 1988,1991,2005 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.

|#

;;;; Control Points
;;; package: (runtime control-point)

(declare (usual-integrations))

(define-integrable (control-point? object)
  (object-type? (ucode-type control-point) object))

(define-integrable (control-point/reusable? control-point)
  (system-vector-ref control-point 0))

(define-integrable (control-point/unused-length control-point)
  (object-datum (system-vector-ref control-point 1)))

(define-integrable (control-point/interrupt-mask control-point)
  (control-point-ref control-point 1))

(define-integrable (control-point/history control-point)
  (control-point-ref control-point 3))

(define-integrable (control-point/previous-history-offset control-point)
  (control-point-ref control-point 4))

(define-integrable (control-point/previous-history-control-point control-point)
  (control-point-ref control-point 5))

(define-integrable (control-point-ref control-point index)
  (system-vector-ref control-point (control-point-index control-point index)))

(define-integrable (control-point-index control-point index)
  (+ (control-point/unused-length control-point) (fix:+ 2 index)))

(define-integrable (control-point/first-element-index control-point)
  (control-point-index control-point 6))

#|

;;; Disabled because some procedures in conpar.scm and uenvir.scm
;;; depend on the actual length for finding compiled code variables,
;;; etc.

(define (control-point/n-elements control-point)
  (let ((real-length
	 (fix:- (system-vector-length control-point)
		(control-point/first-element-index control-point))))
    (if (control-point/next-control-point? control-point)
	(fix:- real-length 2)
	real-length)))
|#

(define (control-point/n-elements control-point)
  (fix:- (system-vector-length control-point)
	 (control-point/first-element-index control-point)))

(define (control-point/element-stream control-point)
  (let ((end
	 (let ((end (system-vector-length control-point)))
	   (if (control-point/next-control-point? control-point)
	       (fix:- end 2)
	       end))))
    (let loop ((index (control-point/first-element-index control-point)))
      (if (fix:< index end)
	  (if ((ucode-primitive primitive-object-type? 2)
	       (ucode-type manifest-nm-vector)
	       (system-vector-ref control-point index))
	      (let ((n-skips
		     (object-datum (system-vector-ref control-point index))))
		(cons-stream
		 (make-non-pointer-object n-skips)
		 (let skip-loop ((n n-skips) (index (fix:+ index 1)))
		   (if (fix:> n 0)
		       (cons-stream #f (skip-loop (fix:- n 1) (fix:+ index 1)))
		       (loop index)))))
	      (cons-stream (map-reference-trap
			    (lambda ()
			      (system-vector-ref control-point index)))
			   (loop (fix:+ index 1))))
	  '()))))

(define (control-point/next-control-point control-point)
  (and (control-point/next-control-point? control-point)
       (system-vector-ref control-point
			  (fix:- (system-vector-length control-point) 1))))

(define (make-control-point reusable?
			    unused-length
			    interrupt-mask
			    history
			    previous-history-offset
			    previous-history-control-point
			    element-stream
			    next-control-point)
  (let ((unused-length
	 (if (eq? microcode-id/stack-type 'STACKLETS)
	     (fix:max unused-length 7)
	     unused-length)))
    (let ((result
	   (make-vector (+ 8
			   unused-length
			   (stream-length element-stream)
			   (if next-control-point 2 0))))
	  (index 0))
      (let ((assign
	     (lambda (value)
	       (vector-set! result index value)
	       (set! index (fix:+ index 1))
	       unspecific)))
	(assign reusable?)
	(assign (make-non-pointer-object unused-length))
	(set! index (fix:+ index unused-length))
	(assign (ucode-return-address restore-interrupt-mask))
	(assign interrupt-mask)
	(assign (ucode-return-address restore-history))
	(assign history)
	(assign previous-history-offset)
	(assign previous-history-control-point)
	(stream-for-each (lambda (element)
			   (assign (unmap-reference-trap element)))
			 element-stream)
	(if next-control-point
	    (begin
	      (assign (ucode-return-address join-stacklets))
	      (assign next-control-point))))
      (object-new-type (ucode-type control-point) result))))

(define (control-point/next-control-point? control-point)
  ((ucode-primitive primitive-object-eq? 2)
   (system-vector-ref control-point
		      (fix:- (system-vector-length control-point) 2))
   (ucode-return-address join-stacklets)))