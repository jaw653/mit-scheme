;;; -*-Scheme-*-
;;;
;;; $Id: imail-file.scm,v 1.59 2000/08/18 16:55:20 cph Exp $
;;;
;;; Copyright (c) 1999-2000 Massachusetts Institute of Technology
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation; either version 2 of the
;;; License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;;; IMAIL mail reader: file-based folder support

(declare (usual-integrations))

;;;; URL

(define-class <file-url> (<url>)
  (pathname define accessor))

(define-method url-body ((url <file-url>))
  (pathname->url-body (file-url-pathname url)))

(define-method url-presentation-name ((url <file-url>))
  (file-namestring (file-url-pathname url)))

(define-method url-body-container-string ((url <file-url>))
  (pathname->url-body (directory-namestring (file-url-pathname url))))

(define-method url-base-name ((url <file-url>))
  (pathname-name (file-url-pathname url)))

(define-method url-exists? ((url <file-url>))
  (file-exists? (file-url-pathname url)))

(define (pathname->url-body pathname)
  (string-append (let ((device (pathname-device pathname)))
		   (if (string? device)
		       (string-append "/" device ":")
		       ""))
		 (let ((directory (pathname-directory pathname)))
		   (if (pair? directory)
		       (string-append
			(if (eq? (car directory) 'ABSOLUTE) "/" "")
			(decorated-string-append
			 "" "" "/"
			 (map (lambda (string)
				(url:encode-string
				 (if (eq? string 'UP) ".." string)))
			      (cdr directory))))
		       ""))
		 (url:encode-string (file-namestring pathname))))

(define (parse-file-url-body string default-pathname)
  (let ((finish
	 (lambda (string)
	   (merge-pathnames
	    (let ((s
		   (decorated-string-append
		    "" "/" ""
		    (map url:decode-string (burst-string string #\/ #f)))))
	      (if (and (eq? (host/type-name (pathname-host default-pathname))
			    'DOS)
		       (re-string-match "/[a-z]:" s #t))
		  (string-tail s 1)
		  s))
	    default-pathname))))
    (cond ((string-prefix? "//localhost/" string)
	   (finish (string-tail string (string-length "//localhost"))))
	  ((string-prefix? "///" string)
	   (finish (string-tail string (string-length "//"))))
	  ((string-prefix? "//" string)
	   (error:bad-range-argument string 'PARSE-URL-BODY))
	  (else
	   (finish string)))))

;;;; Server operations

(define-method %url-complete-string
    ((string <string>) (default-url <file-url>)
		       if-unique if-not-unique if-not-found)
  (pathname-complete-string
   (parse-file-url-body string
			(directory-pathname (file-url-pathname default-url)))
   (lambda (pathname) pathname #t)
   (lambda (string)
     (if-unique (pathname->url-body string)))
   (lambda (prefix get-completions)
     (if-not-unique (pathname->url-body prefix)
		    (lambda () (map pathname->url-body (get-completions)))))
   if-not-found))

(define-method %url-string-completions
    ((string <string>) (default-url <file-url>))
  (map pathname->url-body
       (pathname-completions-list
	(parse-file-url-body
	 string
	 (directory-pathname (file-url-pathname default-url)))
	(lambda (pathname) pathname #t))))

(define-method %delete-folder ((url <file-url>))
  (delete-file (file-url-pathname url)))

;;; The next method only works when operating on two URLs of the same
;;; class, and is restricted to cases where RENAME-FILE works.

(define-computed-method %rename-folder ((uc1 <file-url>) (uc2 <file-url>))
  (and (eq? uc1 uc2)
       (lambda (url new-url)
	 (rename-file (file-url-pathname url) (file-url-pathname new-url)))))

(define-method with-open-connection ((url <file-url>) thunk)
  url
  (thunk))

;;;; Folder

(define-class (<file-folder> (predicate)) (<folder>)
  (messages define standard
	    accessor %file-folder-messages
	    initial-value 'UNKNOWN)
  (file-modification-time define standard
			  initial-value #f)
  (file-modification-count define standard
			   initial-value #f))

(define (file-folder-messages folder)
  (if (eq? 'UNKNOWN (%file-folder-messages folder))
      (revert-file-folder folder))
  (%file-folder-messages folder))

(define-generic revert-file-folder (folder))

(define (file-folder-pathname folder)
  (file-url-pathname (folder-url folder)))

(define-method %close-folder ((folder <file-folder>))
  (without-interrupts
   (lambda ()
     (let ((messages (%file-folder-messages folder)))
       (if (not (eq? 'UNKNOWN messages))
	   (begin
	     (set-file-folder-messages! folder 'UNKNOWN)
	     (for-each detach-message! messages)))))))

(define-method folder-length ((folder <file-folder>))
  (length (file-folder-messages folder)))

(define-method %get-message ((folder <file-folder>) index)
  (list-ref (file-folder-messages folder) index))

(define-method %append-message ((message <message>) (url <file-url>))
  (let ((folder (get-memoized-folder url)))
    (if folder
	(let ((message (make-message-copy message folder)))
	  (without-interrupts
	   (lambda ()
	     (set-file-folder-messages!
	      folder
	      (let ((messages (file-folder-messages folder)))
		(if (pair? messages)
		    (begin
		      (let loop
			  ((prev messages)
			   (this (cdr messages))
			   (index 1))
			(if (pair? this)
			    (loop this (cdr this) (fix:+ index 1))
			    (begin
			      (attach-message! message folder index)
			      (set-cdr! prev (list message)))))
		      messages)
		    (begin
		      (attach-message! message folder 0)
		      (list message))))))))
	(append-message-to-file message url))))

(define-generic make-message-copy (message folder))
(define-generic append-message-to-file (message url))

(define-method expunge-deleted-messages ((folder <file-folder>))
  (without-interrupts
   (lambda ()
     (let find-first ((messages (file-folder-messages folder)) (prev #f))
       (if (pair? messages)
	   (if (message-deleted? (car messages))
	       (let loop
		   ((messages messages)
		    (prev prev)
		    (index (message-index (car messages))))
		 (if (pair? messages)
		     (let ((next (cdr messages)))
		       (if (message-deleted? (car messages))
			   (begin
			     (detach-message! (car messages))
			     (if prev
				 (set-cdr! prev next)
				 (set-file-folder-messages! folder next))
			     (folder-modified! folder 'EXPUNGE index)
			     (loop next prev index))
			   (begin
			     (set-message-index! (car messages) index)
			     (loop (cdr messages) messages (+ index 1)))))))
	       (find-first (cdr messages) messages)))))))

(define-method search-folder ((folder <file-folder>) criteria)
  (cond ((string? criteria)
	 (let ((n (folder-length folder)))
	   (let loop ((index 0) (winners '()))
	     (if (< index n)
		 (loop (+ index 1)
		       (if (let ((message (get-message folder index)))
			     (or (string-search-forward
				  criteria
				  (header-fields->string
				   (message-header-fields message)))
				 (string-search-forward
				  criteria
				  (file-message-body message))))
			   (cons index winners)
			   winners))
		 (reverse! winners)))))
	(else
	 (error:wrong-type-argument criteria
				    "search criteria"
				    'SEARCH-FOLDER))))

(define-method folder-sync-status ((folder <file-folder>))
  (let ((sync-time (file-folder-file-modification-time folder))
	(sync-count (file-folder-file-modification-count folder))
	(current-count (folder-modification-count folder))
	(current-time (file-modification-time (file-folder-pathname folder))))
    (if (and sync-time sync-count)
	(if current-time
	    (if (= sync-time current-time)
		(if (= sync-count current-count)
		    'SYNCHRONIZED
		    'CACHE-MODIFIED)
		(if (= sync-count current-count)
		    'PERSISTENT-MODIFIED
		    'BOTH-MODIFIED))
	    'PERSISTENT-DELETED)
	'UNSYNCHRONIZED)))

(define-method save-folder ((folder <file-folder>))
  (and (let ((status (folder-sync-status folder)))
	 (or (memq status '(FOLDER-MODIFIED PERSISTENT-DELETED))
	     (and (eq? status 'BOTH-MODIFIED)
		  (imail-ui:prompt-for-yes-or-no?
		   "Disk file has changed since last read.  Save anyway"))))
       (begin
	 (synchronize-file-folder-write folder write-file-folder)
	 #t)))

(define-generic write-file-folder (folder pathname))

(define (synchronize-file-folder-write folder writer)
  (let ((pathname (file-folder-pathname folder)))
    (let loop ()
      (let ((count (folder-modification-count folder)))
	(writer folder pathname)
	(let ((t (file-modification-time pathname)))
	  (if (and t (= count (folder-modification-count folder)))
	      (begin
		(set-file-folder-file-modification-count! folder count)
		(set-file-folder-file-modification-time! folder t))
	      (loop)))))))

(define (synchronize-file-folder-read folder reader)
  (let ((pathname (file-folder-pathname folder)))
    (let loop ()
      (let ((t (file-modification-time pathname)))
	(reader folder pathname)
	(if (= t (file-modification-time pathname))
	    (begin
	      (set-file-folder-file-modification-time! folder t)
	      (set-file-folder-file-modification-count!
	       folder
	       (folder-modification-count folder)))
	    (loop))))))

(define-method discard-folder-cache ((folder <file-folder>))
  (close-folder folder))

(define-method probe-folder ((folder <file-folder>))
  folder
  unspecific)

(define-method folder-connection-status ((folder <file-folder>))
  folder
  'NO-SERVER)

(define-method disconnect-folder ((folder <file-folder>))
  folder
  unspecific)

(define-method folder-supports-mime? ((folder <file-folder>))
  folder
  #f)

(define-method preload-folder-outlines ((folder <file-folder>))
  folder
  unspecific)

(define-method first-unseen-message-index ((folder <file-folder>))
  folder
  0)

;;;; Message

(define-class <file-message> (<message>)
  (body define accessor))

(define-method file-message-body ((message <message>))
  (with-string-output-port
    (lambda (port)
      (write-message-body message port))))

(define-method write-message-body ((message <file-message>) port)
  (write-string (file-message-body message) port))

(define-method set-message-flags! ((message <file-message>) flags)
  (%set-message-flags! message flags))

(define-method message-length ((message <file-message>))
  (+ (apply + (map header-field-length (message-header-fields message)))
     1
     (string-length (file-message-body message))))

(define-method message-internal-time ((message <file-message>))
  (header-fields->internal-time message))

(define (header-fields->internal-time headers)
  (or (let loop
	  ((headers (get-all-header-fields headers "received")) (winner #f))
	(if (pair? headers)
	    (loop (cdr headers)
		  (let ((time (received-header-time (car headers))))
		    (if (and time (or (not winner) (< time winner)))
			time
			winner)))
	    winner))
      (message-time headers)))

(define (received-header-time header)
  (let ((time
	 (ignore-errors
	  (lambda ()
	    (call-with-values
		(lambda ()
		  (rfc822:received-header-components
		   (header-field-value header)))
	      (lambda (from by via with id for time)
		from by via with id for	;ignored
		time))))))
    (and (not (condition? time))
	 time)))

(define (message-time message)
  (let ((date (get-first-header-field-value message "date" #f)))
    (and date
	 (let ((t
		(ignore-errors
		 (lambda ()
		   (string->universal-time
		    (rfc822:tokens->string
		     (rfc822:strip-comments (rfc822:string->tokens date))))))))
	   (and (not (condition? t))
		t)))))