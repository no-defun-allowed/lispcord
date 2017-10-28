(in-package :lispcord.gateway)

(defun gateway-url ()
  (doit (get-rq "gateway")
	(jparse it)
	(aget "url" it)
	(str-concat it api-suffix)))

(defun send-payload (bot op d)
  ;; make json and send
  (let ((payload (jmake (alist "op" op "d" d))))
    (print (format t "send-payload: ~a~%" payload))
    (wsd:send (bot-conn bot) payload)))


;;wasn't this deprecated in the api?
(defun presence (game-name &optional (status "online"))
  (alist "game" (alist "name" game-name
		       "type" 0)
        "status" status
        "since" (get-universal-time)
        "afk" :false))

(defun send-identify (bot)
  (send-payload bot 2
		(alist "token" (bot-token bot)
		       "properties" (alist "$os" (bot-os bot)
					   "$browser" (bot-lib bot)
					   "$device" (bot-lib bot))
		       "compress" :false
		       "large_threshold" 250
		       "shard" '(1 10)
		       "presence" (presence "hello there" "online"))))

(defun send-status-update (bot)
  (send-payload bot 3 (presence "hello!" "online")))

(defun send-heartbeat (bot)
  (send-payload bot 1 (bot-seq bot)))

;; opcode 0
(defun on-dispatch (bot msg)
  (let ((event (aget "t" msg)) (seq (aget "s" msg)))
    (setf (bot-seq bot) seq)
    (format t "Event: ~a~%" event)
    (format t "Payload: ~a~%" msg)
    (str-case event
      ("READY" (send-status-update bot))
      (:else (error "Received invalid event! ~a~%" event)))))

;; opcode 10
;; not sure how we should actually be passing this bot arg around still ^^;
(defun on-hello (bot msg)
  (let ((heartbeat-interval (aget "heartbeat_interval" (aget "d" msg))))
    (format t "Heartbeat Inverval: ~a~%" heartbeat-interval)
    ;; setup heartbeat interval here
    ;;(TODO): set up heartbeat things here; for now i want it all to compile xD
    ;; should be able to know whether to _identify_ anew or _resume_ here?
    (send-identify bot)))

;; receive message from websock and dispatch to handler
(defun on-recv (bot msg)
  (let ((op (aget "op" msg)))
    (case op
      (0  (on-dispatch bot msg))
      (1  (print msg))
      (7  (print msg))
      (9  (print msg))
      (10 (on-hello bot msg))
      (11 (format t "Received Heartbeat ACK~%"))
      (T ;; not sure if this should be an error to the user or not?
       (error "Received invalid opcode! ~a~%" op)))))


(defun connect (bot)
  (setf (bot-conn bot) (wsd:make-client (gateway-url)))
  (wsd:start-connection (bot-conn bot))
  (wsd:on :open (bot-conn bot)
	  (lambda ()
	    (format t "Connected!~%")))
  (wsd:on :message (bot-conn bot)
	  (lambda (message)
	    (on-recv bot (jparse message))))
  (wsd:on :error (bot-conn bot)
	  (lambda (error) (warn "Websocket error: ~a~%" error)))
  (wsd:on :close (bot-conn bot)
	  (lambda (&key code reason)
	    (format t "Websocket closed with code: ~a~%Reason: ~a~%" code reason))))
