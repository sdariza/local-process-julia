print("\033c")
using Base.Threads
using Oracle: Oracle
using DataFrames
using Parquet
using Dates
using DotEnv
using UUIDs
DotEnv.load!(".env")

# credentials
username = ENV["USERNAME"]
password = ENV["PASSWORD"]
connect_string = ENV["CONNECT_STRING"]
query = ENV["QUERY"]
conn = Oracle.Connection(username, password, connect_string)

const fetch_size = 10000
const num_threads = Threads.nthreads()  # Get the number of threads available
println("num_threads: ", num_threads)
# Function to handle parallel writing
function write_data_parallel(datafetched, thread_id)
	df = DataFrame(datafetched) # create dataframe to save parquet file
	# Convert DateTime into string
	for col in names(df)
		if eltype(df[!, col]) == Dates.DateTime
			df[!, col] = string.(df[!, col])
		end
	end
	file_path = "output/output_$(thread_id)_$(UUIDs.uuid4()).parquet"
	write_parquet(file_path, df)  # Save parquet file in parallel
	println("File written by thread $thread_id: $file_path")
end

@time begin
	Oracle.stmt(conn, query) do stmt
		Oracle.fetch_array_size!(stmt, fetch_size)  # set fetch size
		println("fetch_size: ", Oracle.fetch_array_size(stmt))
		println("cols: ", Oracle.execute(stmt)) # number of columns being queried
		row = true
		task = 1
		datatask = []
		while row !== nothing
			tasks = []
			i = 1
			while i <= fetch_size
				push!(tasks, @async Oracle.fetchrow(stmt))
				i = i + 1
			end
			res = map(fetch, tasks)
			res = filter(x -> !isnothing(x), res)
			if length(res) > 0
				push!(datatask, res)
			else
				row = nothing
			end
			if task % num_threads == 0 && length(datatask) > 0
				# Divide data across available threads for parallel writing
				println("Read data: $(Oracle.row_count(stmt))")
				println("writing $(length(datatask)) files")
				Threads.@threads for i in 1:num_threads
					write_data_parallel(datatask[i], i)
				end
				task = 1
				datatask = []
			else
				task += 1
			end
		end
		if length(datatask) > 0
			# Divide data across available threads for parallel writing
			println("Read data: $(Oracle.row_count(stmt))")
			println("writing $(length(datatask)) files")
			Threads.@threads for i in eachindex(datatask)
				write_data_parallel(datatask[i], i)
			end
		end
	end
end

Oracle.close(conn)
