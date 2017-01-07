defmodule DirectoryService.BackgroundReplication do
  use GenServer
  alias Poison, as: JSON
  alias DirectoryService.Repo
  alias DirectoryService.File, as: FileData
  alias DirectoryService.Server
  alias DirectoryService.Replication
  import Ecto.Query, only: [from: 2]

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work() # Schedule work to be performed at some point
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    replications = Repo.all(Replication)
    for replication <- replications do
      file = Repo.get_by(FileData, id: replication.file_id)
      server = Repo.get_by(Server, id: file.server)
      backup_server = Repo.get_by(Server, id: replication.server_id)
      if file && server && backup_server do
        IO.puts "Replicating " <> to_string(file.id) <> " to " <> to_string(backup_server.id)
        # Read the file from the desired server.
        read_data = Base.url_encode64(JSON.encode!(%{file_id: file.file_id}))
        read_response = HTTPoison.post(server.host <> "/read", 
                                        "{\"data\": \"" <> read_data <> "\"}", 
                                          [{"Content-Type", "application/json"}])
        case read_response do
          {:ok, read_response_data} ->
            File.write("temp_replication/" <> file.filename, read_response_data.body)
            new_filename = "\"" <> to_string(file.owner_id) <> "/" <> file.filename <> "\""
            {:ok, write_response} = HTTPoison.post(backup_server.host <> "/write", {:multipart, [{:file, "temp_replication/" <> file.filename, 
                                                    { ["form-data"], [name: "\"file\"", 
                                                                        filename: new_filename]},
                                                                          [{"Content-Type", Enum.into(read_response_data.headers, %{})["actual-content-type"]}]}]})
            IO.inspect write_response
            write_response = decrypt_request(String.trim(write_response.body, "\""))
            File.rm("temp_replication/" <> file.filename)
            if write_response["result"] do
              # update backup file id
              updated_file = Ecto.Changeset.change file, backup_file_id: write_response["file_id"]
              Repo.update(updated_file)
            end
          {:error, read_response_error} ->
            IO.puts "Error replicating file " <> to_string(file.id)
        end
        Repo.delete(replication)
        IO.puts "Finished Replicating " <> to_string(file.id)
      else
        Repo.delete(replication)
      end
    end

    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  # Decrypts a base 64 string and converts it into a map
  def decrypt_request(request) do
    JSON.decode!(Base.url_decode64!(request))
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 30 * 1000) # Schedule work 30 seconds.
  end
end