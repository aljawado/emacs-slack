;;; slack-file-info-buffer.el ---                    -*- lexical-binding: t; -*-

;; Copyright (C) 2017

;; Author:  <yuya373@yuya373>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'eieio)
(require 'slack-buffer)

(defclass slack-file-info-buffer (slack-buffer)
  ((file :initarg :file :type slack-file)))

(defmethod slack-buffer-name :static ((class slack-file-info-buffer) file team)
  (format "*Slack - %s File: %s"
          (oref team name)
          (or (oref file title)
              (oref file name)
              (oref file id))))

(defun slack-create-file-info-buffer (team file)
  (if-let* ((buffer (slack-buffer-find 'slack-file-info-buffer
                                       file
                                       team)))
      buffer
    (slack-file-info-buffer :team team :file file)))

(defmethod slack-buffer-init-buffer :after ((this slack-file-info-buffer))
  (with-slots (file team) this
    (let ((class (eieio-object-class-name this)))
      (slack-buffer-push-new-3 team class file))))

(defmethod slack-buffer-name ((this slack-file-info-buffer))
  (with-slots (file team) this
    (slack-buffer-name (eieio-object-class-name this)
                       file
                       team)))

(defmethod slack-buffer-init-buffer ((this slack-file-info-buffer))
  (let ((buf (call-next-method)))
    (with-current-buffer buf
      (slack-file-info-mode)
      (slack-buffer--insert this))
    buf))

(defmethod slack-buffer--insert ((this slack-file-info-buffer))
  (let ((inhibit-read-only t))
    (delete-region (point-min) lui-output-marker))
  (with-slots (file team) this
    (lui-insert (slack-to-string file team))))

(defmethod slack-buffer-send-message ((this slack-file-info-buffer) message)
  (with-slots (file team) this
    (slack-file-comment-add-request (oref file id) message team)))

(defmethod slack-buffer-redisplay ((this slack-file-info-buffer))
  (with-current-buffer (slack-buffer-buffer this)
    (let ((cur-point (point))
          (max (marker-position lui-output-marker)))
      (slack-buffer--insert this)
      (if (and (<= (point-min) cur-point)
               (< cur-point max))
          (goto-char cur-point)))))

(defmethod slack-buffer-add-reaction-to-message
  ((this slack-file-info-buffer) reaction _ts)
  (with-slots (file team) this
    (slack-file-add-reaction (oref file id) reaction team)))

(defmethod slack-buffer-add-reaction-to-file-comment
  ((this slack-file-info-buffer) reaction id)
  (with-slots (team) this
    (slack-file-comment-add-reaction id reaction team)))

(defmethod slack-buffer-remove-reaction-from-message
  ((this slack-file-info-buffer) _ts &optional file-comment-id)
  (with-slots (file team) this
    (if file-comment-id
        (slack-file-comment-remove-reaction file-comment-id
                                            (oref file id)
                                            team)
      (slack-file-remove-reaction (oref file id) team))))

(provide 'slack-file-info-buffer)
;;; slack-file-info-buffer.el ends here
