(in-package :lispcord.http)


; send a message!
(defun send (bot channel-id content)
  (post-rq (str-concat "channels/" channel-id "/messages")
	   bot
	   `(("content" . ,content))))


(defun create-msg (bot channel-id message &aux (nonce (nonce)))
  (let* ((response (jparse
		    (discord-req
		     (str-concat "channels/" channel-id "/messages")
		     :bot bot
		     :type :post
		     :content `(("content" . ,message)
				("nonce" . ,nonce)))))
	 (reply-nonce (gethash "nonce" response)))
    (if (equal reply-nonce nonce)
	response
	(error "Could not send message, nonce failure of ~a ~a"
	       nonce reply-nonce))))


(defgeneric from-id (object &optional bot)
  (:documentation "Retrieves the given object type via ID, either from the cache or through a REST call"))