#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/machines/i386/rulflo.scm,v 1.7 1992/02/05 05:03:48 jinx Exp $
$MC68020-Header: /scheme/src/compiler/machines/bobcat/RCS/rules1.scm,v 4.36 1991/10/25 06:49:58 cph Exp $

Copyright (c) 1992 Massachusetts Institute of Technology

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

;;;; LAP Generation Rules: Flonum rules
;;; package: (compiler lap-syntaxer)

(declare (usual-integrations))

;; ****
;; Missing: 2 argument operations and predicates with non-trivial
;; constant arguments.
;; Also missing with (OBJECT->FLOAT (REGISTER ...)) operands.
;; ****

(define-integrable (->sti reg)
  (- reg fr0))

(define (flonum-source! register)
  (->sti (load-alias-register! register 'FLOAT)))

(define (flonum-target! pseudo-register)
  (delete-dead-registers!)
  (->sti (allocate-alias-register! pseudo-register 'FLOAT)))

(define (flonum-temporary!)
  (allocate-temporary-register! 'FLOAT))

(define-rule statement
  ;; convert a floating-point number to a flonum object
  (ASSIGN (REGISTER (? target))
	  (FLOAT->OBJECT (REGISTER (? source))))
  (let* ((source (register-alias source 'FLOAT))
	 (target (target-register-reference target)))
    (LAP (MOV W (@R ,regnum:free-pointer)
	      (&U ,(make-non-pointer-literal
		    (ucode-type manifest-nm-vector)
		    2)))
	 ,@(if (not source)
	       ;; Value is in memory home
	       (let ((off (pseudo-register-offset source))
		     (temp (temporary-register-reference)))
		 (LAP (MOV W ,target (@RO ,regnum:regs-pointer ,off))
		      (MOV W ,temp (@RO ,regnum:regs-pointer ,(+ 4 off)))
		      (MOV W (@RO ,regnum:free-pointer 4) ,target)
		      (MOV W (@RO ,regnum:free-pointer 8) ,temp)))
	       (let ((sti (->sti source)))
		 (if (zero? sti)
		     (LAP (FST D (@RO ,regnum:free-pointer 4)))
		     (LAP (FLD D (ST ,(->sti source)))
			  (FSTP D (@RO ,regnum:free-pointer 4))))))
	 (LEA ,target
	      (@RO ,regnum:free-pointer
		   ,(make-non-pointer-literal (ucode-type flonum) 0)))
	 (ADD W (R ,regnum:free-pointer) (& 12)))))

(define-rule statement
  ;; convert a flonum object to a floating-point number
  (ASSIGN (REGISTER (? target)) (OBJECT->FLOAT (REGISTER (? source))))
  (let* ((source (move-to-temporary-register! source 'GENERAL))
	 (target (flonum-target! target)))
    (LAP ,@(object->address source)
	 (FLD D (@RO ,source 4))
	 (FSTP D (ST ,(1+ target))))))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (OBJECT->FLOAT (CONSTANT (? value))))
  (QUALIFIER (or (= value 0.) (= value 1.)))
  (let ((target (flonum-target! target)))
    (LAP ,@(if (= value 0.)
	       (LAP (FLDZ))
	       (LAP (FLD1)))
	 (FSTP D (ST ,(1+ target))))))

;;;; Flonum Arithmetic

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-1-ARG (? operation) (REGISTER (? source)) (? overflow?)))
  overflow?				;ignore
  ((flonm-1-arg/operator operation) target source))

(define ((flonum-unary-operation/general operate) target source)
  (let* ((source (flonum-source! source))
	 (target (flonum-target! target)))
    (operate target source)))

(define (flonum-1-arg/operator operation)
  (lookup-arithmetic-method operation flonum-methods/1-arg))

(define flonum-methods/1-arg
  (list 'FLONUM-METHODS/1-ARG))

;;; Notice the weird ,', syntax here.
;;; If LAP changes, this may also have to change.

(let-syntax
    ((define-flonum-operation
       (macro (primitive-name opcode)
	 `(define-arithmetic-method ',primitive-name flonum-methods/1-arg
	    (flonum-unary-operation/general
	     (lambda (target source)
	       (if (and (zero? target) (zero? source))
		   (,opcode)
		   (LAP (FLD D (ST ,', source))
			(,opcode)
			(FSTP D (ST ,',(1+ target)))))))))))
  (define-flonum-operation flonum-negate FCHS)
  (define-flonum-operation flonum-abs FABS)
  (define-flonum-operation flonum-sin FSIN)
  (define-flonum-operation flonum-cos FCOS)
  (define-flonum-operation flonum-sqrt FSQRT)
  (define-flonum-operation flonum-round FRND))

(define-arithmetic-method 'flonum-truncate flonum-methods/1-arg
  (flonum-unary-operation/general
   (lambda (target source)
     (let ((temp (temporary-register-reference)))
       (LAP (FSTCW (@R ,regnum:free-pointer))
	    ,@(if (and (zero? target) (zero? source))
		  (LAP)
		  (LAP (FLD D (ST ,source))))
	    (MOV B ,temp (@RO ,regnum:free-pointer 1))
	    (OR B (@RO ,regnum:free-pointer 1) (&U #x0c))
	    (FNLDCW (@R ,regnum:free-pointer))
	    (FRNDINT)
	    (MOV B (@RO ,regnum:free-pointer 1) ,temp)
	    ,@(if (and (zero? target) (zero? source))
		  (LAP)
		  (LAP (FSTP (ST ,(1+ target)))))
	    (FNLDCW (@R ,regnum:free-pointer)))))))

;; This is used in order to avoid using two stack locations for
;; the remainder unary operations.

(define ((flonum-unary-operation/stack-top operate) target source)
  ;; Perhaps this can be improved?
  (let ((source->top (load-machine-register! source fr0)))
    (rtl-target:=machine-register! target fr0)
    (LAP ,@source->top
	 (operate 0 0))))

(define-arithmetic-method 'flonum-log flonum-methods/1-arg
  (flonum-unary-operation/stack-top
   (lambda (target source)
     (if (and (zero? target) (zero? source))
	 (LAP (FLDLN2)
	      (FXCH (ST 1))
	      (FYL2X))
	 (LAP (FLDLN2)
	      (FLD D (ST ,(1+ source)))
	      (FYL2X)
	      (FSTP D (ST ,(1+ target))))))))

(define-arithmetic-method 'flonum-exp flonum-methods/1-arg
  (flonum-unary-operation/stack-top
   (lambda (target source)
     (if (and (zero? target) (zero? source))
	 (LAP (FLDL2E)
	      (FMULP (ST 1) (ST))
	      (F2XM1)
	      (FLD1)
	      (FADDP (ST 1) (ST)))
	 (LAP (FLD D (ST ,source))
	      (FLDL2E)
	      (FMULP (ST 1) (ST))
	      (F2XM1)
	      (FLD1)
	      (FADDP (ST 1) (ST))
	      (FSTP D (ST ,(1+ target))))))))

(define-arithmetic-method 'flonum-tan flonum-methods/1-arg
  (flonum-unary-operation/stack-top
   (lambda (target source)
     (if (and (zero? target) (zero? source))
	 (LAP (FPTAN)
	      (FSTP D (ST 0)))		; FPOP
	 (LAP (FLD D (ST ,source))
	      (FPTAN)
	      (FSTP D (ST 0))		; FPOP
	      (FSTP D (ST ,(1+ target))))))))

(define-arithmetic-method 'flonum-atan flonum-methods/1-arg
  (flonum-unary-operation/stack-top
   (lambda (target source)
     (if (and (zero? target) (zero? source))
	 (LAP (FLD1)
	      (FPATAN))
	 (LAP (FLD D (ST ,source))
	      (FLD1)
	      (FPATAN)
	      (FSTP D (ST ,(1+ target))))))))

#|
;; These really need two locations on the stack.
;; To avoid that, they are rewritten at the RTL level into simpler operations.

(define-arithmetic-method 'flonum-acos flonum-methods/1-arg
  (flonum-unary-operation/general
   (lambda (target source)
     (LAP (FLD D (ST ,source))
	  (FMUL D (ST) (ST 0))
	  (FLD1)
	  (FSUBP D (ST 1) (ST))
	  (FSQRT)
	  (FLD D (ST ,(1+ source)))
	  (FPATAN)
	  (FSTP D (ST ,(1+ target)))))))

(define-arithmetic-method 'flonum-asin flonum-methods/1-arg
  (flonum-unary-operation/general
   (lambda (target source)
     (LAP (FLD D (ST ,source))
	  (FMUL D (ST) (ST 0))
	  (FLD1)
	  (FSUBP D (ST 1) (ST))
	  (FSQRT)
	  (FLD D (ST ,(1+ source)))
	  (FXCH (ST 1))
	  (FPATAN)
	  (FSTP D (ST ,(1+ target)))))))
|#

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-2-ARGS (? operation)
			 (REGISTER (? source1))
			 (REGISTER (? source2))
			 (? overflow?)))
  overflow?				;ignore
  ((flonum-2-args/operator operation) target source1 source2))

(define ((flonum-binary-operation operate) target source1 source2)
  (let ((default
	  (lambda ()
	    (let* ((sti1 (flonum-source! source1))
		   (sti2 (flonum-source! source2)))
	      (operate (flonum-target! target) sti1 sti2)))))
    (cond ((pseudo-register? target)
	   (reuse-pseudo-register-alias
	    source1 target-type
	    (lambda (alias)
	      (let* ((sti1 (->sti alias))
		     (sti2 (if (= source1 source2)
			       sti1
			       (flonum-source! source2))))
		(delete-register! alias)
		(delete-dead-registers!)
		(add-pseudo-register-alias! target alias)
		(operate sti1 sti1 sti2)))
	    (lambda ()
	      (reuse-pseudo-register-alias
	       source2 target-type
	       (lambda (alias2)
		 (let ((sti1 (flonum-source! source1))
		       (sti2 (->sti alias2)))
		   (delete-register! alias2)
		   (delete-dead-registers!)
		   (add-pseudo-register-alias! target alias2)
		   (operate sti2 sti1 sti2)))
	       default))))
	  ((not (eq? target-type (register-type target)))
	   (error "flonum-2-args: Wrong type register"
		  target target-type))
	  (else
	   (default)))))

(define (flonum-2-args/operator operation)
  (lookup-arithmetic-method operation flonum-methods/2-args))

(define flonum-methods/2-args
  (list 'FLONUM-METHODS/2-ARGS))

(define (flonum-1-arg%1/operator operation)
  (lookup-arithmetic-method operation flonum-methods/1-arg%1))

(define flonum-methods/1-arg%1
  (list 'FLONUM-METHODS/1-ARG%1))

(define (flonum-1%1-arg/operator operation)
  (lookup-arithmetic-method operation flonum-methods/1%1-arg))

(define flonum-methods/1%1-arg
  (list 'FLONUM-METHODS/1%1-ARG))

(define (binary-flonum-arithmetic? operation)
  (memq operation '(FLONUM-ADD FLONUM-SUBTRACT FLONUM-MULTIPLY FLONUM-DIVIDE)))

(let-syntax
    ((define-flonum-operation
       (macro (primitive-name op1%2 op1%2p op2%1 op2%1p)
	 `(begin
	    (define-arithmetic-method ',primitive-name flonum-methods/2-args
	      (flonum-binary-operation
	       (lambda (target source1 source2)
		 (cond ((= target source1)
			(cond ((zero? target)
			       (LAP (,op1%2 D (ST) (ST ,',source2))))
			      ((zero? source2)
			       (LAP (,op2%1 D (ST ,',target) (ST))))
			      (else
			       (LAP (FLD D (ST ,',source2))
				    (,op2%1p D (ST ,',(1+ target)) (ST))))))
		       ((= target source2)
			(cond ((zero? target)
			       (LAP (,op2%1 D (ST) (ST ,',source1))))
			      ((zero? source1)
			       (LAP (,op1%2 D (ST ,',target) (ST))))
			      (else
			       (LAP (FLD D (ST ,',source1))
				    (,op1%2p D (ST ,',(1+ target)) (ST))))))
		       (else
			(LAP (FLD D (ST ,',source1))
			     (,op1%2 D (ST) (ST ,',(1+ source2)))
			     (FSTP D (ST ,',(1+ target)))))))))

	    (define-arithmetic-method ',primitive-name flonum-methods/1%1-arg
	      (flonum-unary-operation/general
	       (lambda (target source)
		 (if (= source target)
		     (LAP (FLD1)
			  (,op1%2p D (ST ,',(1+ target)) (ST)))
		     (LAP (FLD1)
			  (,op1%2 D (ST) (ST ,',(1+ source)))
			  (FSTP D (ST ,',(1+ target))))))))

	    (define-arithmetic-method ',primitive-name flonum-methods/1-arg%1
	      (flonum-unary-operation/general
	       (lambda (target source)
		 (if (= source target)
		     (LAP (FLD1)
			  (,op2%1p D (ST ,',(1+ target))))
		     (LAP (FLD1)
			  (,op2%1 D (ST ,',(1+ source)))
			  (FSTP D (ST ,',(1+ target))))))))))))

  (define-flonum-operation flonum-add fadd faddp fadd faddp)
  (define-flonum-operation flonum-subtract fsub fsubp fsubr fsubpr)
  (define-flonum-operation flonum-multiply fmul fmulp fmul fmulp)
  (define-flonum-operation flonum-divide fdiv fdivp fdivr fdivpr))

(define-arithmetic-method 'flonum-atan2 flonum-methods/2-args
  (lambda (target source1 source2)
    (let* ((source1->top (load-machine-register! source fr0))
	   (source2 (flonum-source!)))
      (rtl-target:=machine-register! target fr0)
      (LAP ,@source1->top
	   (FLD D (ST ,source2))
	   (FPATAN)))))

(define-arithmetic-method 'flonum-remainder flonum-methods/2-args
  (flonum-binary-operation
   (lambda (target source1 source2)
     (if (zero? source2)
	 (LAP (FLD D (ST ,source1))
	      (FPREM1)
	      (FSTP D (ST ,(1+ target))))
	 #|
	 ;; This sequence is one cycle shorter than the one below,
	 ;; but needs two spare stack locations instead of one.
	 ;; Since FPREM1 is a variable, very slow instruction,
	 ;; the difference in time will hardly be noticeable
	 ;; but the availability of an extra "register" may be.
	 (LAP (FLD D (ST ,source2))
	      (FLD D (ST ,source1))
	      (FPREM1)
	      (FSTP D (ST ,(+ target 2)))
	      (FSTP D (ST 0)))		; FPOP
	 |#
	 (LAP (FXCH (ST ,source2))
	      (FLD D (ST ,(if (zero? source1)
			      source2
			      source1)))
	      (FPREM1)
	      (FSTP D (ST ,(1+ (if (= target source2)
				   0
				   target))))
	      (FXCH (ST ,source2)))))))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-2-ARGS FLONUM-SUBTRACT
			 (OBJECT->FLOAT (CONSTANT 0.))
			 (REGISTER (? source))
			 (? overflow?)))
  overflow?				;ignore
  ((flonum-unary-operation/general
    (lambda (target source)
      (if (and (zero? target) (zero? source))
	  (LAP (FCHS))
	  (LAP (FLD D (ST ,source))
	       (FCHS)
	       (FSTP D (ST ,(1+ target)))))))
   target source))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-2-ARGS (? operation)
			 (REGISTER (? source))
			 (OBJECT->FLOAT (CONSTANT 1.))
			 (? overflow?)))
  (QUALIFIER (binary-flonum-arithmetic? operation))
  overflow?				;ignore
  ((flonum-unary-operation/general (flonum-1-arg%1/operator operation)
				   target source)))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (FLONUM-2-ARGS (? operation)
			 (OBJECT->FLOAT (CONSTANT 1.))
			 (REGISTER (? source))
			 (? overflow?)))
  (QUALIFIER (binary-flonum-arithmetic? operation))
  overflow?				;ignore
  ((flonum-unary-operation/general (flonum-1%1-arg/operator operation)
   target source)))

;;;; Flonum Predicates

(define-rule predicate
  (FLONUM-PRED-1-ARG (? predicate) (REGISTER (? source)))
  (flonum-compare-zero predicate source))

(define-rule predicate
  (FLONUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? source1))
		      (REGISTER (? source2)))
  (let* ((st1 (flonum-source! source1))
	 (st2 (flonum-source! source2)))
    (cond ((zero? st1)
	   (flonum-branch! predicate
			   (LAP (FCOM D (ST ,st2)))))
	  ((zero? st2)
	   (flonum-branch! (commute-flonum-predicate predicate)
			   (LAP (FCOM D (ST ,st1)))))
	  (else
	   (flonum-branch! predicate
			   (LAP (FLD D (ST ,st1))
				(FCOMP D (ST ,(1+ st2)))))))))

(define-rule predicate
  (FLONUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? source))
		      (OBJECT->FLOAT (CONSTANT 0.)))
  (flonum-compare-zero predicate source))

(define-rule predicate
  (FLONUM-PRED-2-ARGS (? predicate)
		      (OBJECT->FLOAT (CONSTANT 0.))
		      (REGISTER (? source)))
  (flonum-compare-zero (commute-flonum-predicate predicate) source))

(define-rule predicate
  (FLONUM-PRED-2-ARGS (? predicate)
		      (REGISTER (? source))
		      (OBJECT->FLOAT (CONSTANT 1.)))
  (flonum-compare-one predicate source))

(define-rule predicate
  (FLONUM-PRED-2-ARGS (? predicate)
		      (OBJECT->FLOAT (CONSTANT 1.))
		      (REGISTER (? source)))
  (flonum-compare-one (commute-flonum-predicate predicate) source))

(define (flonum-compare-zero predicate source)
  (let ((sti (flonum-source! source)))
    (if (zero? sti)
	(flonum-branch! predicate
			(LAP (FTST)))
	(flonum-branch! (commute-flonum-predicate predicate)
			(LAP (FLDZ)
			     (FCOMP D (ST ,(1+ sti))))))))

(define (flonum-compare-one predicate source)
  (let ((sti (flonum-source! source)))
    (flonum-branch! (commute-flonum-predicate predicate)
		    (LAP (FLD1)
			 (FCOMP D (ST ,(1+ sti)))))))

(define (commute-flonum-predicate pred)
  (case pred
    ((FLONUM-EQUAL? FLONUM-ZERO?) 'FLONUM-EQUAL?)
    ((FLONUM-LESS? FLONUM-NEGATIVE?) 'FLONUM-GREATER?)
    ((FLONUM-GREATER? FLONUM-POSITIVE?) 'FLONUM-LESS?)
    (else
     (error "commute-flonum-predicate: Unknown predicate" pred))))

(define (flonum-branch! predicate prefix)
  (case predicate
    ((FLONUM-EQUAL? FLONUM-ZERO?)
     (set-current-branches! (lambda (label)
			      (LAP (JE (@PCR ,label))))
			    (lambda (label)
			      (LAP (JNE (@PCR ,label))))))
    ((FLONUM-LESS? FLONUM-NEGATIVE?)
     (set-current-branches! (lambda (label)
			      (LAP (JB (@PCR ,label))))
			    (lambda (label)
			      (LAP (JAE (@PCR ,label))))))
    ((FLONUM-GREATER? FLONUM-POSITIVE?)
     (set-current-branches! (lambda (label)
			      (LAP (JA (@PCR ,label))))
			    (lambda (label)
			      (LAP (JBE (@PCR ,label))))))
    (else
     (error "flonum-branch!: Unknown predicate" predicate)))
  (flush-register! eax)
  (LAP ,@prefix
       (FSTSW (R ,eax))
       (SAHF)))