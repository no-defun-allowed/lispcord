(in-package :lispcord.http)

(defclass new-guild ()
  ((name :initarg :name)
   (region :initarg :region)
   (icon :initarg :icon)
   (verify-l :initarg :verify-l)
   (notify-l :initarg :notify-l)
   (roles :initarg :roles)
   (channels :initarg :channels)))

(defclass part-chnl ()
  ((name :initarg :name)
   (type :initarg :type)))

(defclass plac-role (lc:role)
  ((id :initarg :id
       :type fixnum
       :accessor lc:id)))

(defmethod from-id (id (g (eql :guild)) &optional (bot *client*))
  (cache :guild
	 (discord-req (str-concat "guilds/" id)
		      :bot bot)))

(defmethod erase ((g lc:guild) &optional (bot *client*))
  (discord-req (str-concat "guilds/" (lc:id g))
	       :bot bot
	       :type :delete))

(defun get-channels (guild &optional (bot *client*))
  (declare (type (or snowflake lc:guild) guild))
  (let ((g (if (typep guild 'lc:guild) (lc:id guild) guild)))
    (mapvec (curry #'cache :channels)
	    (discord-req (str-concat "guilds/" g "/channels")
			 :bot bot))))

(defmethod create ((c new-chnl) (g lc:guild) &optional (bot *client*))
  (cache :channel
	 (discord-req (str-concat "guilds/" (lc:id g) "/channels")
		      :bot bot
		      :type :post
		      :content (to-json c))))


(defmethod from-id ((u lc:user) (g lc:guild) &optional (bot *client*))
  (from-json :member
	     (discord-req (str-concat "guilds/" (lc:id g)
				      "/members/" (lc:id u))
			  :bot bot)))

(defun get-members (guild &key (limit 1) after (bot *client*))
  (declare (type (or snowflake lc:guild) guild))
  (let ((g (if (typep guild 'lc:guild) (lc:id guild) guild))
	(params (append (if limit `(("limit" . ,(to-string limit))))
			(if after `(("after" . ,(to-string after)))))))
    (mapvec (curry #'from-json :g-member)
	    (discord-req (str-concat "guilds/" g "/members")
			 :parameters params
			 :bot bot))))


(defmethod edit ((m lc:member) (g lc:guild) &optional (bot *client*))
  (discord-req (str-concat "guilds/" (lc:id g)
			   "/members/" (lc:id (lc:user m)))
	       :bot bot
	       :type :patch
	       :content (jmake
			 (list (cons "nick" (or (lc:nick m) :null))
			       (cons "roles" (or (lc:roles m) :null))
			       (cons "mute" (or (lc:mutep m) :false))
			       (cons "deaf" (or (lc:deafp m) :false))))))

(defun move-member (member channel &optional (bot *client*))
  (declare (type lc:member member)
	   (type (or snowflake lc:guild-channel) channel))
  (let ((m (lc:id (lc:user member)))
	(g (lc:guild-id member))
	(c (if (typep channel 'lc:channel) (lc:id channel) channel)))
    (discord-req (str-concat "guilds/" g
			     "/members/" m)
		 :bot bot
		 :type :patch
		 :content (jmake `(("channel_id" . ,c))))))

(defun set-nick (nick guild &optional (bot *client*))
  (declare (type (or snowflake lc:guild) guild))
  (let ((g (if (typep guild 'lc:guild) (lc:id guild) guild)))
    (gethash "nick" (discord-req
		     (str-concat "/guilds/" g "/members/@me/nick")
		     :bot bot
		     :type :patch
		     :content (str-concat "{\"nick\":\"" nick "\"}")))))


(defmethod create ((r lc:role) (m lc:member) &optional (bot *client*))
  (discord-req (str-concat "guilds/" (lc:guild-id m)
			   "/members/" (lc:id (lc:user m))
			   "/roles/" (lc:id r))
	       :bot bot
	       :type :put
	       :content "{}"))

(defun erase-role (role member &optional (bot *client*))
  (declare (type (or snowflake lc:role) role)
	   (type lc:member member))
  (let ((r (if (typep role 'lc:role) (lc:id role) role))
	(m (lc:id (lc:user member)))
	(g (lc:guild-id member)))
    (discord-req (str-concat "guilds/" g
			     "/members/" m
			     "/roles/" r)
		 :bot bot
		 :type :delete)))


(defmethod erase ((m lc:member) &optional (bot *client*))
  (discord-req (str-concat "guilds/" (lc:guild-id m)
			   "/members/" (lc:id (lc:user m)))
	       :bot bot
	       :type :delete))

(defun get-bans (guild &optional (bot *client*))
  (declare (type (or snowflake lc:guild) guild))
  (let ((g (if (typep guild 'lc:guild) (lc:id guild) guild)))
    (discord-req (str-concat "guilds/" g "/bans")
		 :bot bot)))

(defun ban (user guild &optional delete (bot *client*))
  (declare (type (or snowflake lc:user) user)
	   (type (or snowflake lc:guild) guild))
  (let ((u (if (typep user 'lc:user) (lc:id user) user))
	(g (if (typep guild 'lc:guild) (lc:id guild) guild)))
    (discord-req (str-concat "guilds/" g "/bans/" u
			     (if delete
				 (str-concat "?delete-message-days="
					     (to-string delete))
				 ""))
		 :bot bot
		 :type :put
		 :content "{}")))

(defun unban (user guild &optional (bot *client*))
  (declare (type (or snowflake lc:user) user)
	   (type (or snowflake lc:guild) guild))
  (let ((u (if (typep user 'lc:user) (lc:id user) user))
	(g (if (typep guild 'lc:guild) (lc:id guild) guild)))
    (discord-req (str-concat "guilds/" g "/bans/" u)
		 :bot bot
		 :type :delete)))

(defun get-roles (guild &optional (bot *client*))
  (declare (type (or snowflake lc:guild) guild))
  (let ((g (if (typep guild 'lc:guild) (lc:id guild) guild)))
    (mapvec (curry #'cache :role)
	    (discord-req (str-concat "guilds/" g "/roles")
			 :bot bot))))


(defun create ())