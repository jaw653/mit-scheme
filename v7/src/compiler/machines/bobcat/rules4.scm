#| -*-Scheme-*-

$Id: rules4.scm,v 4.14 1993/07/06 00:56:31 gjr Exp $

Copyright (c) 1988-1993 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case. |#

;;;; LAP Generation Rules: Interpreter Calls
;;; package: (compiler lap-syntaxer)

(declare (usual-integrations))

;;;; Variable cache trap handling.

(define-rule statement
  (INTERPRETER-CALL:CACHE-REFERENCE (? cont) (? extension) (? safe?))
  (QUALIFIER (interpreter-call-argument? extension))
  cont					; ignored
  (let ((set-extension
	 (interpreter-call-argument->machine-register! extension d2)))
    (let ((clear-map (clear-map!)))
      (LAP ,@set-extension
	   ,@clear-map
	   (JSR ,(if safe?
		     entry:compiler-safe-reference-trap
		     entry:compiler-reference-trap))))))

(define-rule statement
  (INTERPRETER-CALL:CACHE-ASSIGNMENT (? cont) (? extension) (? value))
  (QUALIFIER (and (interpreter-call-argument? extension)
		  (interpreter-call-argument? value)))
  cont					; ignored
  (let ((set-extension
	 (interpreter-call-argument->machine-register! extension d2)))
    (let ((set-value (interpreter-call-argument->machine-register! value d3)))
      (let ((clear-map (clear-map!)))
	(LAP ,@set-extension
	     ,@set-value
	     ,@clear-map
	     (JSR ,entry:compiler-assignment-trap))))))

(define-rule statement
  (INTERPRETER-CALL:CACHE-UNASSIGNED? (? cont) (? extension))
  (QUALIFIER (interpreter-call-argument? extension))
  cont					; ignored
  (let ((set-extension
	 (interpreter-call-argument->machine-register! extension d2)))
    (let ((clear-map (clear-map!)))
      (LAP ,@set-extension
	   ,@clear-map
	   ,@(invoke-interface-jsr code:compiler-unassigned?-trap)))))

;;;; Interpreter Calls

;;; All the code that follows is obsolete.  It hasn't been used in a while.
;;; It is provided in case the relevant switches are turned off, but there
;;; is no real reason to do this.  Perhaps the switches should be removed.

(define (interpreter-call-argument? expression)
  (or (rtl:register? expression)
      (rtl:constant? expression)
      (and (rtl:cons-pointer? expression)
	   (rtl:machine-constant? (rtl:cons-pointer-type expression))
	   (rtl:machine-constant? (rtl:cons-pointer-datum expression)))
      (rtl:simple-offset? expression)))

(define (interpreter-call-argument->machine-register! expression register)
  (let ((target (register-reference register)))
    (case (car expression)
      ((REGISTER)
       (load-machine-register! (rtl:register-number expression) register))
      ((CONSTANT)
       (LAP ,@(clear-registers! register)
	    ,@(load-constant (rtl:constant-value expression) target)))
      ((CONS-POINTER)
       (LAP ,@(clear-registers! register)
	    ,@(load-non-pointer (rtl:machine-constant-value
				 (rtl:cons-pointer-type expression))
				(rtl:machine-constant-value
				 (rtl:cons-pointer-datum expression))
				target)))
      ((OFFSET)
       (let ((source-reference (offset->reference! expression)))
	 (LAP ,@(clear-registers! register)
	      (MOV L ,source-reference ,target))))
      (else
       (error "Unknown expression type" (car expression))))))

(define-rule statement
  (INTERPRETER-CALL:ACCESS (? cont) (? environment) (? name))
  (QUALIFIER (interpreter-call-argument? environment))
  cont					; ignored
  (lookup-call code:compiler-access environment name))

(define-rule statement
  (INTERPRETER-CALL:LOOKUP (? cont) (? environment) (? name) (? safe?))
  (QUALIFIER (interpreter-call-argument? environment))
  cont					; ignored
  (lookup-call (if safe? code:compiler-safe-lookup code:compiler-lookup)
	       environment name))

(define-rule statement
  (INTERPRETER-CALL:UNASSIGNED? (? cont) (? environment) (? name))
  (QUALIFIER (interpreter-call-argument? environment))
  cont					; ignored
  (lookup-call code:compiler-unassigned? environment name))

(define-rule statement
  (INTERPRETER-CALL:UNBOUND? (? cont) (? environment) (? name))
  (QUALIFIER (interpreter-call-argument? environment))
  cont					; ignored
  (lookup-call code:compiler-unbound? environment name))

(define (lookup-call code environment name)
  (let ((set-environment
	 (interpreter-call-argument->machine-register! environment d2)))
    (let ((clear-map (clear-map!)))
      (LAP ,@set-environment
	   ,@clear-map
	   ,@(load-constant name (INST-EA (D 3)))
	   ,@(invoke-interface-jsr code)))))

(define-rule statement
  (INTERPRETER-CALL:DEFINE (? cont) (? environment) (? name) (? value))
  (QUALIFIER (and (interpreter-call-argument? environment)
		  (interpreter-call-argument? value)))
  cont					; ignored
  (assignment-call code:compiler-define environment name value))

(define-rule statement
  (INTERPRETER-CALL:SET! (? cont) (? environment) (? name) (? value))
  (QUALIFIER (and (interpreter-call-argument? environment)
		  (interpreter-call-argument? value)))
  cont					; ignored
  (assignment-call code:compiler-set! environment name value))

(define (assignment-call code environment name value)
  (let ((set-environment
	 (interpreter-call-argument->machine-register! environment d2)))
    (let ((set-value (interpreter-call-argument->machine-register! value d4)))
      (let ((clear-map (clear-map!)))
	(LAP ,@set-environment
	     ,@set-value
	     ,@clear-map
	     ,@(load-constant name (INST-EA (D 3)))
	     ,@(invoke-interface-jsr code))))))