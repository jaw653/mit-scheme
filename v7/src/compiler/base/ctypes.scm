#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/base/ctypes.scm,v 4.11 1989/04/17 18:42:36 cph Exp $

Copyright (c) 1988, 1989 Massachusetts Institute of Technology

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

;;;; Compiler CFG Datatypes

(declare (usual-integrations))

;;;; Application

(define-snode application
  type
  context
  operator
  operands
  (parallel-node owner)
  (operators		;used in simulate-application
   args-passed-out?)	;used in outer-analysis
  operand-values	;set by outer-analysis, used by identify-closure-limits
  continuation-push
  model			;set by identify-closure-limits, used in generation
  destination-block	;used by identify-closure-limits to quench propagation
  frame-adjustment	;set by setup-frame-adjustments, used in generation
  reuse-existing-frame?	;set by setup-frame-adjustments, used in generation
  )

(define *applications*)

(define (make-application type block operator operands continuation-push)
  (let ((application
	 (make-snode application-tag
		     type block operator operands false '() '()
		     continuation-push false true false false)))
    (set! *applications* (cons application *applications*))
    (add-block-application! block application)
    (if (rvalue/reference? operator)
	(add-lvalue-application! (reference-lvalue operator) application))
    (make-scfg application '())))

(define-vector-tag-unparser application-tag
  (lambda (state application)
    ((case (application-type application)
       ((COMBINATION)
	(standard-unparser "COMBINATION" false))
       ((RETURN)
	(standard-unparser "RETURN"
	  (lambda (state return)
	    (unparse-object state (return/operand return)))))
       (else
	(standard-unparser "APPLICATION"	  (lambda (state application)
	    (unparse-object state (application-type application))))))
     state application)))

(define-integrable (application-block application)
  (reference-context/block (application-context application)))

(define-snode parallel
  application-node
  subproblems)

(define *parallels*)

(define (make-parallel application subproblems)
  (let ((parallel (make-snode parallel-tag false subproblems)))
    (set-parallel-application-node! parallel application)
    (set-application-parallel-node! application parallel)
    (set! *parallels* (cons parallel *parallels*))
    (snode->scfg parallel)))

(define (make-combination block continuation operator operands
			  continuation-push)
  (let ((application
	 (make-application 'COMBINATION
			   block
			   (subproblem-rvalue operator)
			   (cons continuation
				 (map subproblem-rvalue operands))
			   continuation-push)))
    (scfg*scfg->scfg!
     (make-parallel (cfg-entry-node application) (cons operator operands))
     application)))

(define-integrable (application/combination? application)
  (eq? (application-type application) 'COMBINATION))

(define-integrable combination/context application-context)
(define-integrable combination/operator application-operator)
(define-integrable combination/inliner application-operators)
(define-integrable set-combination/inliner! set-application-operators!)
(define-integrable combination/frame-size application-operand-values)
(define-integrable set-combination/frame-size! set-application-operand-values!)
(define-integrable combination/inline? combination/inliner)
(define-integrable combination/continuation-push application-continuation-push)
(define-integrable combination/model application-model)
(define-integrable set-combination/model! set-application-model!)
(define-integrable combination/frame-adjustment application-frame-adjustment)
(define-integrable set-combination/frame-adjustment!
  set-application-frame-adjustment!)
(define-integrable combination/reuse-existing-frame?
  application-reuse-existing-frame?)
(define-integrable set-combination/reuse-existing-frame?!
  set-application-reuse-existing-frame?!)

(define-integrable (combination/block combination)
  (reference-context/block (combination/context combination)))

(define-integrable (combination/continuation combination)
  (car (application-operands combination)))

(define-integrable (combination/operands combination)
  (cdr (application-operands combination)))

(define-structure (inliner (type vector) (conc-name inliner/))
  (handler false read-only true)
  (generator false read-only true)
  operands)

(define-integrable (make-return block continuation rvalue)
  (make-application 'RETURN block continuation (list rvalue) false))

(define-integrable (application/return? application)
  (eq? (application-type application) 'RETURN))

(define-integrable return/context application-context)
(define-integrable return/operator application-operator)
(define-integrable return/continuation-push application-continuation-push)
(define-integrable (return/operand return)
  (car (application-operands return)))

;;; This method of handling constant combinations has the feature that
;;; such combinations are handled exactly like RETURNs by the
;;; procedure classification phase, which occurs after all constant
;;; combinations have been identified.

(define (combination/constant! combination rvalue)
  (let ((continuation (combination/continuation combination)))
    (for-each (lambda (continuation)
		(set-continuation/combinations!
		 continuation
		 (delq! combination (continuation/combinations continuation)))
		(set-continuation/returns!
		 continuation
		 (cons combination (continuation/returns continuation))))
	      (rvalue-values continuation))
    (for-each (lambda (operator)
		(if (rvalue/procedure? operator)
		    (set-procedure-applications!
		     operator
		     (delq! combination (procedure-applications operator)))))
	      (rvalue-values (combination/operator combination)))
    (set-application-type! combination 'RETURN)
    (set-application-operator! combination continuation)
    (set-application-operands! combination (list rvalue))
    (let ((push (combination/continuation-push combination)))
      (if (and push (rvalue-known-value continuation))
	  (set-virtual-continuation/type! (virtual-return-operator push)
					  continuation-type/effect)))))

;;;; Miscellaneous Node Types

(define-snode assignment
  context
  lvalue
  rvalue)

;; (define *assignments*)

(define (make-assignment block lvalue rvalue)
  (lvalue-connect! lvalue rvalue)
  (let ((assignment (make-snode assignment-tag block lvalue rvalue)))
    ;; (set! *assignments* (cons assignment *assignments*))
    (variable-assigned! lvalue assignment)
    (snode->scfg assignment)))

(define-integrable (node/assignment? node)
  (eq? (tagged-vector/tag node) assignment-tag))

(define-snode definition
  context
  lvalue
  rvalue)

(define (make-definition block lvalue rvalue)
  (lvalue-connect! lvalue rvalue)
  (snode->scfg (make-snode definition-tag block lvalue rvalue)))

(define-integrable (node/definition? node)
  (eq? (tagged-vector/tag node) definition-tag))

(define-pnode true-test
  context
  rvalue)

(define (make-true-test block rvalue)
  (pnode->pcfg (make-pnode true-test-tag block rvalue)))

(define-integrable (node/true-test? node)
  (eq? (tagged-vector/tag node) true-test-tag))

(define-snode fg-noop)

(define (make-fg-noop)
  (make-snode fg-noop-tag))

(define-integrable (node/fg-noop? node)
  (eq? (tagged-vector/tag node) fg-noop-tag))

(cfg-node-tag/noop! fg-noop-tag)

(define-snode virtual-return
  context
  operator
  operand)

(define (make-virtual-return block operator operand)
  (snode->scfg (make-snode virtual-return-tag block operator operand)))

(define-integrable (node/virtual-return? node)
  (eq? (tagged-vector/tag node) virtual-return-tag))

(define (make-push block rvalue)
  (make-virtual-return block
		       (virtual-continuation/make block continuation-type/push)
		       rvalue))

(define-snode pop
  continuation)

(define (make-pop continuation)
  (snode->scfg (make-snode pop-tag continuation)))

(define-integrable (node/pop? node)
  (eq? (tagged-vector/tag node) pop-tag))

(define-snode stack-overwrite
  context
  target
  continuation)

(define (make-stack-overwrite block target continuation)
  (snode->scfg (make-snode stack-overwrite-tag block target continuation)))

(define-integrable (node/stack-overwrite? node)
  (eq? (tagged-vector/tag node) stack-overwrite-tag))

;;; Node Properties

(define-integrable (node/subgraph-color node)
  (cfg-node-get node node/subgraph-color-tag))

(define-integrable (set-node/subgraph-color! node color)
  (cfg-node-put! node node/subgraph-color-tag color))

(define node/subgraph-color-tag
  "subgraph-color-tag")

(define-structure (subgraph-color
		   (conc-name subgraph-color/)
		   (constructor make-subgraph-color ()))
  (nodes '())
  (rgraph false))