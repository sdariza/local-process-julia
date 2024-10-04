#=
Script to download Oracle data in .parquet files
=#
print("\033c")
using Base.Threads
import Oracle
using DataFrames
using Parquet
using Dates
using DotEnv
using UUIDs
DotEnv.load!(".env.dev")

# credentials
username = ENV["USERNAME"]
password = ENV["PASSWORD"]
connect_string = ENV["CONNECT_STRING"]
query = ENV["QUERY"]
conn = Oracle.Connection(username, password, connect_string)

# Initialize global variables
const fetch_size = 10
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

# Prepared statement to execute a query
Oracle.stmt(conn, query) do stmt
    Oracle.fetch_array_size!(stmt, fetch_size)  # set fetch size
    println("fetch_size: ", Oracle.fetch_array_size(stmt))
    println("cols: ", Oracle.execute(stmt)) # number of columns being queried
    row = Oracle.fetchrow(stmt)  # fetch one row at a time manually
    rownum = Oracle.row_count(stmt)  # get number of fetched rows
    task = 1
    datatask = []
    while row !== nothing
        datafetched = []
        i = 1
        while i <= fetch_size && row !== nothing
            push!(datafetched, row)
            row = Oracle.fetchrow(stmt)
            i = i + 1
        end
        push!(datatask, datafetched)
        if task % num_threads == 0
            # Divide data across available threads for parallel writing
            println("Read data: $(Oracle.row_count(stmt)-1)")
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
    # if there are more tasks
    if length(datatask) > 0
        println("Read data: $(Oracle.row_count(stmt))")
        Threads.@threads for i in eachindex(datatask)
            write_data_parallel(datatask[i], i)
        end
    end
end

println("All done! Go to output folder")

# Close oracle connection
Oracle.close(conn)
