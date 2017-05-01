;;; spotify.el --- control the Spotify app from Emacs

;; Copyright (C) 2014-2016 Daniel Fernandes Martins

;; Keywords: multimedia, music, spotify
;; Package: spotify

;; Commentary:

;; This mode requires at least GNU Emacs 24.4 and Python 2.7

;; Before using this mode, first go the Spotify Web API console
;; <https://developer.spotify.com/my-applications> and create a new
;; application, adding <http://localhost:8591/> as the redirect URI.
;;
;; After requiring `spotify', make sure to define the client id and client
;; secrets, along with some other important settings:
;;
;; (custom-set-variables
;;  '(spotify-oauth2-client-id "client-id")
;;  '(spotify-oauth2-client-secret "client-secret")
;;
;;  ; Only for Mac OS X, for now
;;  '(spotify-transport 'apple) 
;;  '(spotify-osascript-bin-path "/usr/bin/osascript"))
;;
;; To authenticate, invoke the `spotify-connect' function. This will start the
;; Oauth2 authentication and authorization workflow. You may be asked to type
;; a password since the tokens are stored as an encrypted file in the local
;; filesystem. After you enter your credentials and authorizes the app, you
;; should see a greeting message in the echo area.
;;
;; To search for tracks, invoke the `spotify-track-search' function and
;; type your query. The results will be shown up in a new buffer. To play the
;; track under the cursor, just type RET, or type M-RET to play the
;; track's album from the start.

;; Code:

(when (version< emacs-version "24.4")
  (error "Spotify requires at least GNU Emacs 24.4"))

(require 'json)
(require 'oauth2)
(require 'tabulated-list)

(require 'spotify-api)
(require 'spotify-track-search)
(require 'spotify-playlist-search)
(require 'spotify-controller)
(require 'spotify-remote)

(when-darwin    (require 'spotify-apple))
(when-gnu-linux (require 'spotify-dbus))

(defgroup spotify nil
  "Spotify client."
  :version "0.0.1"
  :group 'multimedia)

;;;###autoload
(defun spotify-track-search (query)
  "Searches for tracks that match the given query string."
  (interactive "sSpotify Search (Tracks): ")
  (let* ((buffer-name (format "*Track Search: %s*" query))
         (display-buffer-alist (list `(,buffer-name display-buffer-same-window)))
         (buffer (get-buffer-create (format "*Track Search: %s*" query))))
    (with-current-buffer buffer
      (spotify-track-search-mode)
      (spotify-track-search-set-list-format)
      (setq-local spotify-query query)
      (setq-local spotify-current-page 1)
      (setq tabulated-list-entries nil)
      (pop-to-buffer buffer)
      (spotify-track-search-update 1)
      buffer)))

;;;###autoload
(defun spotify-playlist-search (query)
  "Searches for playlists that match the given query string."
  (interactive "sSpotify Search (Playlists): ")
  (let* ((buffer-name (format "*Playlist Search: %s*" query))
         (display-buffer-alist (list `(,buffer-name display-buffer-same-window)))
         (buffer (get-buffer-create buffer-name)))
    (with-current-buffer buffer
      (spotify-playlist-search-mode)
      (setq-local spotify-query query)
      (setq-local spotify-current-page 1)
      (setq tabulated-list-entries nil)
      (pop-to-buffer buffer)
      (spotify-playlist-search-update 1)
      buffer)))

;;;###autoload
(defun spotify-my-playlists ()
  "Displays the current user's playlists."
  (interactive)
  (spotify-user-playlists (spotify-current-user-id)))

;;;###autoload
(defun spotify-user-playlists (user-id)
  "Displays the public playlists of the given user."
  (interactive "sSpotify User ID: ")
  (let* ((buffer-name (format "*Playlists: %s*" user-id))
         (display-buffer-alist (list `(,buffer-name display-buffer-same-window)))
         (buffer (get-buffer-create buffer-name)))
    (with-current-buffer buffer
      (spotify-playlist-search-mode)
      (setq-local spotify-user-id user-id)
      (setq-local spotify-current-page 1)
      (setq tabulated-list-entries nil)
      (pop-to-buffer buffer)
      (spotify-user-playlists-update user-id 1)
      buffer)))

;;;###autoload
(defun spotify-featured-playlists ()
  "Displays Spotify's featured playlists."
  (interactive)
  (let ((display-buffer-alist (list `("*Featured Playlists*" display-buffer-same-window)))
        (buffer (get-buffer-create "*Featured Playlists*")))
    (with-current-buffer buffer
      (spotify-playlist-search-mode)
      (setq-local spotify-current-page 1)
      (setq tabulated-list-entries nil)
      (pop-to-buffer buffer)
      (spotify-featured-playlists-update 1)
      buffer)))

;;;###autoload
(defun spotify-create-playlist (name is-public)
  "Creates an empty playlist owned by the current user."
  (interactive
   (list (read-string "Playlist name: ")
         (y-or-n-p "Make the playlist public? ")))
  (let ((new-playlist (spotify-api-playlist-create (spotify-current-user-id) name is-public)))
    (message (format "Playlist '%s' created" (spotify-get-item-name new-playlist)))))

(provide 'spotify)


