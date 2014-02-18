;;;
;;; Load NBA data into PostgreSQL
;;;

(in-package #:nba)

(defparameter *model* (asdf:system-relative-pathname :nba "nba.sql"))
(defparameter *games* (asdf:system-relative-pathname :nba "games.bson"))

(defstruct team id score home won)

(defun get-team-id (hash-team)
  "Return a proper structure for a team."
  (let* ((name (gethash "name" hash-team))
         (abbr (gethash "abbreviation" hash-team))
         (sql  (format nil "
with newteam as (
  insert into nba.team(name, abbrev)
       select '~a', '~a'
        where not exists (select 1
                            from nba.team
                           where name = '~a')
    returning id
)
   select id from newteam
union all
   select id from team where name = '~a'
limit 1"
                       name abbr name name)))
    (query sql :single)))

(defun get-team-details (hash-team)
  "Return details about a HASH-TEAM entry."
  (make-team :id    (get-team-id hash-team)
             :score (gethash "score" hash-team)
             :home  (gethash "home" hash-team)
             :won   (= 1 (gethash "won" hash-team))))

(defun get-teams (hash-game)
  "Return the host team from the HASH-GAME."
  (let* ((teams (gethash "teams" hash-game))
         (a     (get-team-details (first teams)))
         (b     (get-team-details (second teams)))
         (host  (if (team-home a) a b))
         (guest (if (team-home a) b a)))
    (cons host guest)))

(defparameter stats-columns
  '(ast blk drb fg fg3 fg3_pct fg3a fg_pct fga
    ft ft_pct fta mp orb pf pts stl tov trb))

(defun get-stats (hash-game team)
  "Get the team stats hash in the box entry of HASH-GAME, where the first
   set of values refer to the team who won."
  (let ((box (gethash "box" hash-game)))
    (if (team-won team)
        (gethash "team" (first box))
        (gethash "team" (second box)))))

(defun insert-team-stats (game-id team hash-game)
  "Insert team stats into our PostgreSQL database."
  (let* ((stats (get-stats hash-game team))
         (sql (format nil "
insert into team_stats(game, team, ~{~a~^, ~})
     values (~a, ~a, ~{~a~^, ~})"
                      stats-columns
                      game-id
                      (team-id team)
                      (mapcar (lambda (stat)
                                (let* ((sname (string-downcase (symbol-name stat)))
                                       (value (gethash sname stats)))
                                  (if (or (null value)
                                          (and (stringp value)
                                               (string= value "")))
                                      "DEFAULT"
                                      value)))
                              stats-columns))))
    (execute sql)))

(defun insert-game (hash-game)
  "Insert a single HASH-GAME into PostgreSQL."
  (let* ((date  (gethash "date" hash-game))
         (teams (get-teams hash-game))
         (sql   (format nil "
insert into game (date, host, guest, host_score, guest_score)
          values ('~a', '~a', '~a', '~a', '~a')
       returning id"
                        date
                        (team-id (car teams))
                        (team-id (cdr teams))
                        (team-score (car teams))
                        (team-score (cdr teams)))))
    (let ((game-id (query sql :single)))
      (insert-team-stats game-id (car teams) hash-game)
      (insert-team-stats game-id (cdr teams) hash-game))))

(defun load-games (&key
                     (host   "localhost")
                     (port   54393)
                     (user   "dim")
                     (pass   "none")
                     (dbname "nba")
                     (games *games*))
  "Load the BSON formated file GAMES into a PostgreSQL database."
  (let ((count 0))
    (with-connection (list dbname user pass host :port port)
      (execute "set search_path to nba;")
      (execute "truncate team, game cascade;")
      (with-transaction ()
        (with-open-file (s games :element-type 'unsigned-byte)
          (handler-case
              (loop for hash-game = (decode s)
                 do (progn
                      (insert-game hash-game)
                      (incf count)))
            (end-of-file (e)
              (declare (ignore e)))))))
    count))
