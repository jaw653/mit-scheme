#| -*-Scheme-*-

$Id: edextra.scm,v 1.15 1992/09/30 18:30:03 cph Exp $

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

;;;; 6.001: Edwin Extensions

(declare (usual-integrations))

(load-edwin-library 'PRINT)

(define-command print-graphics
  "Print out the last displayed picture."
  '()
  (lambda ()
    (call-with-last-picture-file
     (lambda (filename)
       (if filename
	   (begin
	     (message "Spooling...")
	     (shell-command
	      false false false false
	      (string-append "/users/u6001/bin/print-pgm.sh "
			     filename
			     " "
			     (print/assemble-switches "Scheme Picture" '())))
	     (append-message "done"))
	   (editor-error "No picture to print!"))))))

(environment-link-name '(edwin)
		       '(student pictures)
		       'call-with-last-picture-file)

(define (restore-focus-to-editor)
  (let ((screen (selected-screen)))
    (if (xterm-screen/grab-focus! screen)
	(xterm-screen/flush! screen))))

(environment-link-name '(student pictures)
		       '(edwin)
		       'restore-focus-to-editor)

;;;; EDWIN Command "Load Problem Set"

;;; Wired-in pathnames

;;; We look in the "psn" subdir for problem set n
(define pset-dir "/users/u6001/psets/")
(define pset-list-file (merge-pathnames "probsets.scm" pset-dir))
(define student-dir "/users/u6001/work/")

;;; The structure "problem-sets" must be loaded from pset-list-file whenever
;;; the set of available problem sets changes, or when the default
;;; problem set changes.  Files should appear with name and extension, but
;;; without device, directory, or version; these will be supplied
;;; automatically.
;;;
;;; Example problem-sets variable:

;(define problem-sets
;  `(1 (1  (load&reference "ps1-c-curve.scm" "ps1-debug.scm"))
;      (2  (copy "ps2-ans.scm") (load&reference "ps2-primes.scm"))
;      (3  (copy "ps3-ans.scm")
;	  (load&reference "ps3-squares.scm" "ps3-tri.scm"))
;      (4  (copy "ps4-ans.scm") (load&reference "ps4-doctor.scm")
;	  (select "ps4-ans.scm"))
;      (5  (copy "ps5-ans.scm")
;	  (load&reference "ps5-graph.scm" "ps5-imp.scm" "ps5-res.scm"))
;      (6  (copy "ps6-mods.scm") (load&reference "ps6-adv.scm"))
;      (7  (copy "ps7-ans.scm")
;	  (load&reference "ps7-ps.scm" "ps7-psutil.scm" "ps7-ratnum.scm"))
;      (8  (copy "ps8-mods.scm") (load&reference "ps8-mceval.scm"))))

;;; Data abstraction for the "problem-sets" object:

(define problem-sets/default-ps car)
(define problem-sets/psets cdr)
(define psets/first-pset car)
(define psets/rest-psets cdr)
(define psets/empty? null?)
(define pset/ps car)
(define pset/groups cdr)
(define (groups/files-to-copy groups)
  (let ((any (assq 'copy groups)))
    (if any (cdr any) '())))
(define (groups/files-to-load groups)
  (let ((any (assq 'load groups)))
    (if any (cdr any) '())))
(define (groups/files-to-reference groups)
  (let ((any (assq 'reference groups)))
    (if any (cdr any) '())))
(define (groups/files-to-load&reference groups)
  (let ((any (assq 'load&reference groups)))
    (if any (cdr any) '())))
(define (groups/buffer-to-select groups)
  (let ((any (assq 'select groups)))
    (if any (cadr any) '())))
(define (groups/all-files groups)
  (merge-lists (groups/files-to-copy groups)
	       (groups/files-to-load groups)
	       (groups/files-to-reference groups)
	       (groups/files-to-load&reference groups)))

;;; Procedure to get the "files" object corresponding to a particular
;;; problem set.  Runs error-handler (which should never return) if
;;; the problem set number is not listed in the "problem-sets" object.

(define (ps-groups ps error-handler)
  (let loop ((remaining-psets (problem-sets/psets problem-sets)))
    (if (psets/empty? remaining-psets)
	(error-handler)
	(let ((first-ps (psets/first-pset remaining-psets)))
	  (if (string=? ps (->string (pset/ps first-ps)))
	      (pset/groups first-ps)
	      (loop (psets/rest-psets remaining-psets)))))))

;;; Horribly inefficient procedure to merge lists, ensuring that no member
;;; is repeated in the resulting list.
(define (merge-lists . lists)
  (let ((one-list (apply append lists)))
    (let loop ((remaining one-list)
	       (accumulated '()))
      (if (null? remaining)
	  accumulated
	  (let ((first (car remaining))
		(rest (cdr remaining)))
	    (if (memq first rest)
		(loop rest accumulated)
		(loop rest (cons first accumulated))))))))

;;; Returns #t iff FILES all exist in DIRECTORY.
(define (files-all-exist? files directory)
  (for-all? files
    (lambda (file)
      (file-exists? (merge-pathnames directory file)))))

(define (->string object)
  (if (string? object)
      object
      (with-output-to-string (lambda () (display object)))))

(define-command Load-Problem-Set
  "Load a 6.001 problem set."
  ()
  (lambda ()
    (load pset-list-file (->environment '(edwin)))
    (let* ((default-ps (problem-sets/default-ps problem-sets))
	   (ps (prompt-for-string "Load Problem Set" (->string default-ps))))
      (let* ((error-handler
	      (lambda ()
		(editor-error "There doesn't appear to be a problem set "
			      ps
			      " installed; ask a TA for help.")))
	     (groups (ps-groups ps error-handler))
	     (pset-path
	      (merge-pathnames (string-append "ps" (->string ps) "/") 
			       pset-dir)))
	(if (not (files-all-exist? (groups/all-files groups) pset-path))
	    (error-handler))
	(map (lambda (file)
	       (find-file (merge-pathnames pset-path (->pathname file))))
	     (groups/files-to-reference groups))
	(map (lambda (file)
	       (let ((filename (merge-pathnames pset-path (->pathname file))))
		 (message "Evaluating file " (->namestring filename))
		 (load filename (->environment '(student)))
		 (append-message " -- done")))
	     (groups/files-to-load groups))
	(map (lambda (file)
	       (let ((filename (merge-pathnames pset-path (->pathname file))))
		 (message "Evaluating file " (->namestring filename))
		 (load filename (->environment '(student)))
		 (append-message " -- done")
		 (find-file filename)))
	     (groups/files-to-load&reference groups))
	(map (lambda (file)
	       (let ((source-file
		      (merge-pathnames pset-path (->pathname file)))
		     (dest-file
		      (merge-pathnames student-dir (->pathname file))))
		 (message "Copying file "
			  (->namestring file)
			  " to working area")
		 (let ((buffer (find-buffer (->namestring dest-file))))
		   (if buffer (kill-buffer buffer)))
		 (find-file source-file)
		 (let ((buffer (current-buffer)))
		   (set-buffer-writeable! buffer)
		   (set-visited-pathname buffer dest-file)
		   (write-buffer buffer))
		 (append-message " -- done")
		 (find-file dest-file)))
	     (groups/files-to-copy groups))))))

;;;; DOS Filenames

(define valid-dos-filename?
  (let ((invalid-chars
	 (char-set-invert
	  (char-set-union
	   (char-set-union char-set:lower-case char-set:numeric)
	   (char-set #\_ #\^ #\$ #\! #\# #\% #\& #\-
		     #\{ #\} #\( #\) #\@ #\' #\`)))))
    (lambda (filename)
      (let ((end (string-length filename))
	    (valid-name?
	     (lambda (end)
	       (and (<= 1 end 8)
		    (not (substring-find-next-char-in-set filename 0 end
							  invalid-chars))
		    (not
		     (there-exists? '("clock$" "con" "aux" "com1" "com2"
					       "com3" "com4" "lpt1" "lpt2"
					       "lpt3" "nul" "prn")
		       (lambda (name)
			 (substring=? filename 0 end
				      name 0 (string-length name)))))))))
	(let ((dot (string-find-next-char filename #\.)))
	  (if (not dot)
	      (valid-name? end)
	      (and (valid-name? dot)
		   (<= 2 (- end dot) 4)
		   (not (substring-find-next-char-in-set filename (+ dot 1) end
							 invalid-chars)))))))))


(define dos-filename-description
  "DOS filenames are between 1 and 8 characters long, inclusive.  They
may optionally be followed by a period and a suffix of 1 to 3
characters.

In other words, a valid filename consists of:

* 1 to 8 characters, OR

* 1 to 8 characters, followed by a period, followed by 1 to 3
  characters.

The characters that may be used in a filename (or a suffix) are:

* The lower case letters: a b c ... z

* The digits: 0 1 2 ... 9

* These special characters: ' ` ! @ # $ % ^ & ( ) - _ { }

The period (.) may appear exactly once as a separator between the
filename and the suffix.

The following filenames are reserved and may not be used:

	aux	clock$	com1	com2	com3	com4
	con	lpt1	lpt2	lpt3	nul	prn")

;;;; Overrides of Editor Procedures

(set! os/auto-save-pathname
      (let ((usual os/auto-save-pathname))
	(lambda (pathname buffer)
	  (if pathname
	      (if (student-directory? pathname)
		  (pathname-new-type pathname "asv")
		  (usual pathname buffer))
	      (let ((directory (buffer-default-directory buffer)))
		(if (student-directory? directory)
		    (merge-pathnames
		     (let ((name
			    (string-append
			     (let ((name (buffer-name buffer)))
			       (let ((index (string-find-next-char name #\.)))
				 (if (not index)
				     (if (> (string-length name) 8)
					 (substring name 0 8)
					 name)
				     (substring name 0 (min 8 index)))))
			     ".asv")))
		       (if (valid-dos-filename? name)
			   name
			   "default.asv"))
		     directory)
		    (usual pathname buffer)))))))

(set! os/precious-backup-pathname
      (let ((usual os/precious-backup-pathname))
	(lambda (pathname)
	  (if (student-directory? pathname)
	      (pathname-new-type pathname "bak")
	      (usual pathname)))))

(set! os/default-backup-filename
      (lambda () (string-append working-directory "default.bak")))

(set! os/buffer-backup-pathname
      (let ((usual os/buffer-backup-pathname))
	(lambda (truename)
	  (if (student-directory? truename)
	      (values (pathname-new-type truename "bak") '())
	      (usual truename)))))

;;; These next two depend on the fact that they are only invoked when
;;; the current buffer is the Dired buffer that is being tested.

(set! os/backup-filename?
      (let ((usual os/backup-filename?))
	(lambda (filename)
	  (if (student-directory? (dired-buffer-directory (current-buffer)))
	      (equal? "bak" (pathname-type filename))
	      (usual filename)))))

(set! os/auto-save-filename?
      (let ((usual os/auto-save-filename?))
	(lambda (filename)
	  (if (student-directory? (dired-buffer-directory (current-buffer)))
	      (equal? "asv" (pathname-type filename))
	      (usual filename)))))

(set! default-homedir-pathname
      (lambda () (->pathname student-dir)))

(define (dired-buffer-directory buffer)
  ;; Similar to the definition in "dired.scm".  That definition should
  ;; be exported in order to eliminate this redundant definition.
  (or (buffer-get buffer 'DIRED-DIRECTORY)
      (buffer-default-directory buffer)))

(set! standard-editor-initialization
      (let ((usual standard-editor-initialization))
	(lambda ()
	  (usual)
	  (standard-login-initialization))))

(set! prompt-for-pathname*
      (let ((usual prompt-for-pathname*))
	(lambda (prompt directory verify-final-value? require-match?)
	  (let ((pathname
		 (usual prompt directory verify-final-value? require-match?)))
	    (if (or (not (student-directory? pathname))
		    (valid-dos-filename? (file-namestring pathname))
		    (file-exists? pathname)
		    (with-saved-configuration
		     (lambda ()
		       (delete-other-windows (current-window))
		       (select-buffer
			(temporary-buffer " *invalid-filename-dialog*"))
		       (append-string
			"The file name you have specified,\n\n\t")
		       (append-string (file-namestring pathname))
		       (append-string
			"

is not a valid name for a DOS disk.  If you create a file with this
name, you will not be able to save it to your floppy disk.

If you want to use this name anyway, answer \"yes\" to the question
below.  Otherwise, answer \"no\" to use a different name.
----------------------------------------------------------------------
")
		       (append-string dos-filename-description)
		       (prompt-for-yes-or-no? "Use this non-DOS name"))))
		pathname
		(prompt-for-pathname* prompt directory
				      verify-final-value? require-match?))))))

(define (student-directory? pathname)
  (string-prefix? working-directory (->namestring pathname)))

;;;; Customization

(set! editor-can-exit? false)
(set! scheme-can-quit? false)
(set! paranoid-exit? true)
(set! x-screen-auto-raise true)

(set-variable! enable-transcript-buffer true)
(set-variable! evaluate-in-inferior-repl true)
(set-variable! repl-error-decision true)
(set-variable! version-control true)
(set-variable! trim-versions-without-asking true)
(set-variable! enable-compressed-files false)
(set-variable! enable-encrypted-files false)

(set-variable! completion-ignored-extensions
	       (append '(".bci" ".bif" ".bin" ".com" ".ext")
		       (ref-variable completion-ignored-extensions)))

(set-variable!
 mail-header-function
 (let ((default-reply-to false))
   (lambda (point)
     (let ((reply-to
	    (prompt-for-string "Please enter an email address for replies"
			       default-reply-to
			       'INSERTED-DEFAULT)))
       (if (not (string-null? reply-to))
	   (begin
	     (set! default-reply-to reply-to)
	     (insert-string "From: " point)
	     (insert-string reply-to point)
	     (insert-newline point)
	     (insert-string "Reply-to: " point)
	     (insert-string reply-to point)
	     (insert-newline point)))))))

(set-variable! select-buffer-not-found-hooks
	       (cons (lambda (name)
		       (find-file-noselect (merge-pathnames name
							    working-directory)
					   true))
		     (ref-variable select-buffer-not-found-hooks)))

;; Disable key bindings that exit the editor.
;; M-x logout is all the students should need.
(define-key 'fundamental '(#\c-x #\c-c) false)
(define-key 'fundamental '(#\c-x #\c-z) false)
(define-key 'fundamental '(#\c-x #\c) false)
(define-key 'fundamental '(#\c-x #\z) false)