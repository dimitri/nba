;;;; nba.asd

(asdf:defsystem #:nba
    :serial t
    :description "Load NBA data into PostgreSQL"
    :author "Dimitri Fontaine <dim@tapoueh.org>"
    :license "WTFPL"
    :depends-on (#:uiop			; host system integration
		 #:postmodern		; PostgreSQL protocol implementation
		 #:cl-postgres		; low level bits for COPY streaming
		 #:simple-date		; FIXME: recheck dependency
                 #:mongo-cl-driver)
    :components ((:file "package")
                 (:file "nba" :depends-on ("package"))))


