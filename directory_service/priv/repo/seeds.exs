# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DirectoryService.Repo.insert!(%DirectoryService.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias DirectoryService.Repo
alias DirectoryService.File
alias DirectoryService.Server
alias DirectoryService.Replication

Repo.delete_all File
Repo.delete_all Server
Repo.delete_all Replication
