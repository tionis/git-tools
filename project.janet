(declare-project
  :name "git-tools"
  :description "some tools to make working with git easier"
  :dependencies ["https://github.com/janet-lang/spork"
                 "https://tasadar.net/tionis/jeff"]
  :author "tionis.dev"
  :license "MIT"
  :url "https://tasadar.net/tionis/jeff"
  :repo "git+https://tasadar.net/tionis/jeff")

(each f (filter |(peg/match ~(sequence "git-" (any 1) -1) $0) (os/dir "git-tools"))
  (declare-executable # Install janet git tools
    :name f
    :entry (string "git-tools/" f)
    :install true))

(each f (os/dir "bin") # Install shell scripts
  (declare-bin
    :main (string "bin/" f)))

(each f (if (os/stat "binscript") (os/dir "binscript") [])
  (declare-binscript # Install simple janet scripts
    :main (string "binscript/" f)
    :hardcode-syspath false
    :is-janet false))

(each f (if (os/stat "man") (os/dir "man") [])
  (declare-manpage # Install man pages
    (string "man/" f)))

(declare-source # Declare source files to be imported by other janet based scripts
  :source ["git-tools"])
