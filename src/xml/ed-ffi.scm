#| -*-Scheme-*-

$Id: ed-ffi.scm,v 1.9 2006/02/18 04:31:38 cph Exp $

Copyright 2001,2005,2006 Massachusetts Institute of Technology

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

;;;; XML: Edwin buffer packaging info

(standard-scheme-find-file-initialization
 '#(("rdf-nt" (runtime rdf nt))
    ("rdf-struct" (runtime rdf structures))
    ("xhtml" (runtime xml html))
    ("xhtml-entities" (runtime xml html))
    ("xml-chars" (runtime xml parser))
    ("xml-names" (runtime xml names))
    ("xml-rpc" (runtime xml xml-rpc))
    ("xml-struct" (runtime xml structure))
    ("xml-output" (runtime xml output))
    ("xml-parser" (runtime xml parser))))