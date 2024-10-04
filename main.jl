#=
Script to download Oracle data in .parquet files
=#
print("\033c")
import Oracle
using DataFrames
using Parquet
using Dates
using DotEnv

DotEnv.load!(".env")

# credentials
username = ENV["USERNAME"]
password = ENV["PASSWORD"]
connect_string = ENV["CONNECT_STRING"]
query = ENV["QUERY"]

# Initialize global variables
global filenum::Int = 0
const fetch_size = UInt64(10000)

# connect database
conn = Oracle.Connection(username, password, connect_string)

# prepared statement to execute a query
Oracle.stmt(conn, query) do stmt
    Oracle.fetch_array_size!(stmt, fetch_size)  # set fetch size
    println("fetch_size: ", Oracle.fetch_array_size(stmt))
    println("cols: ", Oracle.execute(stmt)) # number of columns being queried
    row = Oracle.fetchrow(stmt) # fetch one row at a time manually
    rownum = Oracle.row_count(stmt) # get number of fetched rows
    while row !== nothing
        datafetched = []
        while rownum % fetch_size != 0 && row !== nothing
            push!(datafetched, row)
            row = Oracle.fetchrow(stmt)
            rownum = Oracle.row_count(stmt)
        end
        println("Read data: ", rownum)
        df = DataFrame(datafetched) # create dataframe to save parquet file
        # convert DateTime into string
        for col in names(df)
            if eltype(df[!, col]) == Dates.DateTime
                df[!, col] = string.(df[!, col])
            end
        end
        write_parquet("output/output$filenum.parquet", df) # save parquet file
        global filenum
        filenum += 1
    end
end

println("All done! Go to output folder")
Oracle.close(conn)
